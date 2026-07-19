import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:netmanager/components/base/body/home/widgets/cell_section.dart';
import 'package:netmanager/components/base/body/home/widgets/empty_state.dart';
import 'package:netmanager/components/base/body/home/widgets/loading_state.dart';
import 'package:netmanager/components/base/body/home/widgets/network_data.dart';
import 'package:netmanager/components/base/body/home/widgets/primary_cell_card.dart';
import 'package:netmanager/database/cell_database.dart';
import 'package:netmanager/l10n/app_localizations.dart';
import 'package:netmanager/utils/cell_utils.dart';
import 'package:netmanager/utils/haptic_service.dart';
import 'package:netmanager/utils/screenshot_helper.dart';
import 'package:netmanager/types/cell/sim_data.dart';
import 'package:netmanager/utils/simdata_parser.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

class HomeBody extends StatefulWidget {
  const HomeBody(
    this.platform,
    this.sharedPreferences,
    this.homeLoadedNotifier,
    this.platformSignalNotifier,
    this.debugNotifier,
    this.updateIntervalNotifier,
    this.externalDatabasesNotifier, {
    super.key,
    this.onUpdateButtonPressed,
    this.onScreenshotButtonPressed,
  });

  final MethodChannel platform;
  final SharedPreferences sharedPreferences;
  final ValueNotifier<bool> homeLoadedNotifier;
  final ValueNotifier<int> platformSignalNotifier;
  final ValueNotifier<bool> debugNotifier;
  final ValueNotifier<int> updateIntervalNotifier;
  final ValueNotifier<bool> externalDatabasesNotifier;

  final ValueSetter<VoidCallback>? onUpdateButtonPressed;
  final ValueSetter<VoidCallback>? onScreenshotButtonPressed;

  @override
  State<HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> {
  late MethodChannel platform;
  late Timer timer;
  late SharedPreferences sharedPreferences;
  late ValueNotifier<bool> homeLoadedNotifier;
  late ValueNotifier<int> platformSignalNotifier;
  late ValueNotifier<bool> debugNotifier;

  static const double cardWidth = 185;
  static const double cardHeight = 75;

  final GlobalKey _captureKey = GlobalKey();

  final ValueNotifier<bool> _isUpdatingNotifier = ValueNotifier(false);
  final ValueNotifier<bool> _altCellViewNotifier = ValueNotifier(false);

  late AppLocalizations _appLocalizations;

  int _simCount = 0;
  String _debug = "";
  String _plmn = "";
  bool _pageLoaded = false;

  SIMData? _simData;
  int _factor = 1;

  final Map<int, String> _cellDescriptions = {};

  @override
  void initState() {
    super.initState();
    _appLocalizations = AppLocalizations.of(context)!;
    platform = widget.platform;
    sharedPreferences = widget.sharedPreferences;
    homeLoadedNotifier = widget.homeLoadedNotifier;
    debugNotifier = widget.debugNotifier;

    widget.onUpdateButtonPressed?.call(update);
    widget.onScreenshotButtonPressed?.call(
      () => ScreenshotHelper.captureAndShare(
        context: context,
        captureKey: _captureKey,
        platform: platform,
      ),
    );

    startTimer();

    widget.platformSignalNotifier.addListener(restartTimer);
    widget.updateIntervalNotifier.addListener(restartTimer);
  }

  @override
  void dispose() {
    widget.onUpdateButtonPressed?.call(() {});
    widget.onScreenshotButtonPressed?.call(() {});
    timer.cancel();

    widget.platformSignalNotifier.removeListener(restartTimer);
    widget.updateIntervalNotifier.removeListener(restartTimer);

    _isUpdatingNotifier.dispose();
    _altCellViewNotifier.dispose();

    super.dispose();
  }

  Future<void> update() async {
    if (_isUpdatingNotifier.value) return;

    _isUpdatingNotifier.value = true;

    final stopwatch = Stopwatch()..start();

    try {
      _simCount = await platform.invokeMethod("getSimCount") ?? 0;
      final jsonStr = await platform.invokeMethod("getNetworkData") ?? "";

      if (jsonStr == null || jsonStr.isEmpty) {
        setState(() {
          _debug = _appLocalizations.homeNoData;
          _simData = null;
        });

        return;
      }

      final SIMData? simData;

      try {
        simData = await compute<String, SIMData?>(parseSimData, jsonStr);
      } catch (e) {
        if (!mounted) return;

        setState(() {
          _debug = "$jsonStr\n${_appLocalizations.error}: $e";
        });

        return;
      }

      if (simData == null) return;

      _plmn = simData.networkPlmn;
      _factor = conversionFactor(simData.primaryCell);
      int? node = int.tryParse(simData.primaryCell.cellIdentifier);

      if (simData.activeCells.isEmpty && node != null) {
        simData.activeCells.add(simData.primaryCell);
      }
      if (!isValidString(simData.primaryCell.cellIdentifier)) {
        simData.activeCells.clear();
      }
      simData.activeCells.sort(
        (a, b) => (b.isRegistered ? 1 : 0).compareTo(a.isRegistered ? 1 : 0),
      );

      final Set<int> cidsToSearch = {};

      for (final cell in simData.activeCells) {
        final int? cid = int.tryParse(cell.cellIdentifier);
        if (cid != null) cidsToSearch.add(cid);
      }

      for (final cell in simData.neighborCells) {
        final int? cid = int.tryParse(cell.cellIdentifier);
        if (cid != null) cidsToSearch.add(cid);
      }

      _cellDescriptions.removeWhere((cid, _) => !cidsToSearch.contains(cid));
      final Set<int> missingCids = cidsToSearch.difference(
        _cellDescriptions.keys.toSet(),
      );

      if (widget.externalDatabasesNotifier.value &&
          missingCids.isNotEmpty &&
          _plmn.isNotEmpty) {
        Map<int, String> foundData = await CellDatabase.fetchCells(
          _plmn,
          cidsToSearch,
        );

        _cellDescriptions.addAll(foundData);
      }

      setState(() {
        _simData = simData;
        _debug = jsonStr;
        _cellDescriptions;
      });
    } on PlatformException catch (e) {
      await Sentry.captureException(e, stackTrace: e.stacktrace);
      setState(() {
        _debug = "${_appLocalizations.platformException}: ${e.toString()}";
      });
    } finally {
      stopwatch.stop();
      final elapsed = stopwatch.elapsedMilliseconds;

      if (elapsed < 300) {
        await Future.delayed(Duration(milliseconds: 300 - elapsed));
      }

      if (mounted) {
        _isUpdatingNotifier.value = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final widgetsHeight =
        MediaQuery.of(context).size.height -
        kToolbarHeight -
        kBottomNavigationBarHeight -
        MediaQuery.of(context).padding.top;

    if (!homeLoadedNotifier.value) {
      return LoadingState(minHeight: widgetsHeight);
    }

    if (_simCount == 0) {
      return EmptyState(
        minHeight: widgetsHeight,
        icon: Icons.sim_card_alert_outlined,
        message: _appLocalizations.homeNoSim,
      );
    }

    if (homeLoadedNotifier.value &&
        _pageLoaded &&
        (_plmn.isEmpty || _plmn == "00000")) {
      return EmptyState(
        minHeight: widgetsHeight,
        icon: Icons.airplanemode_on_outlined,
        message: _appLocalizations.homeAirplane,
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Column(
        children: <Widget>[
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: ValueListenableBuilder(
                      valueListenable: _isUpdatingNotifier,
                      builder: (context, isUpdating, child) {
                        return isUpdating
                            ? const LinearProgressIndicator()
                            : const SizedBox(height: 4);
                      },
                    ),
                  ),
                ],
              ),
              RepaintBoundary(
                key: _captureKey,
                child: Material(
                  color: Theme.of(context).colorScheme.surface,
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.all(10.0),
                        child: Column(
                          children: [
                            if (_simData != null) ...[
                              PrimaryCellCard(
                                cell: _simData!.primaryCell,
                                altCellView: _altCellViewNotifier,
                                factor: _factor,
                                onToggle: () {
                                  HapticService().triggerHaptic(
                                    HapticType.selection,
                                    context,
                                  );

                                  _altCellViewNotifier.value =
                                      !_altCellViewNotifier.value;
                                },
                                cardWidth: cardWidth,
                                cardHeight: cardHeight,
                              ),
                              NetworkData(
                                simData: _simData!,
                                cardWidth: cardWidth,
                                cardHeight: cardHeight,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (_simData != null && _simData!.activeCells.isNotEmpty)
                        CellSection(
                          title: _appLocalizations.homeActiveCells,
                          cells: _simData!.activeCells,
                          factor: _factor,
                          isActive: true,
                          descriptions: widget.externalDatabasesNotifier.value
                              ? _cellDescriptions
                              : {},
                        ),
                    ],
                  ),
                ),
              ),
              if (_simData != null && _simData!.neighborCells.isNotEmpty) ...[
                CellSection(
                  title: _appLocalizations.homeNeighborCells,
                  cells: _simData!.neighborCells,
                  factor: _factor,
                  isActive: false,
                  descriptions: widget.externalDatabasesNotifier.value
                      ? _cellDescriptions
                      : {},
                ),
              ],
              ValueListenableBuilder(
                valueListenable: debugNotifier,
                builder: (context, isDebugOn, child) {
                  return isDebugOn && _debug.isNotEmpty && _debug != "null"
                      ? Container(
                          margin: const EdgeInsets.only(
                            top: 10,
                            left: 20,
                            right: 20,
                            bottom: 20,
                          ),
                          child: Text("${_appLocalizations.debug}: $_debug"),
                        )
                      : const SizedBox.shrink();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void startTimer() {
    update();

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;

      update();
      _pageLoaded = true;
      homeLoadedNotifier.value = true;
    });

    timer = Timer.periodic(
      Duration(seconds: widget.updateIntervalNotifier.value),
      (Timer t) {
        update();
      },
    );
  }

  void restartTimer() {
    timer.cancel();
    _altCellViewNotifier.value = false;
    startTimer();
  }
}
