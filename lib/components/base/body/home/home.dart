import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:netmanager/components/base/body/home/widgets/cell_section.dart';
import 'package:netmanager/components/base/body/home/widgets/empty_state.dart';
import 'package:netmanager/components/base/body/home/widgets/loading_state.dart';
import 'package:netmanager/components/base/body/home/widgets/network_data.dart';
import 'package:netmanager/components/base/body/home/widgets/primary_cell_card.dart';
import 'package:netmanager/components/modals/graphs_modal.dart';
import 'package:netmanager/database/cell_database.dart';
import 'package:netmanager/l10n/app_localizations.dart';
import 'package:netmanager/types/cell/cell_data.dart';
import 'package:netmanager/types/graph/graph_metric.dart';
import 'package:netmanager/types/graph/graph_point.dart';
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
    this.controller,
    this.platform,
    this.sharedPreferences,
    this.homeLoadedNotifier,
    this.platformSignalNotifier,
    this.debugNotifier,
    this.updateIntervalNotifier,
    this.externalDatabasesNotifier,
    this.homeDataGraphsNotifier,
    this.homeGraphsRetentionTimeNotifier,
    this.currentSimSlotNotifier, {
    super.key,
    this.onUpdateButtonPressed,
    this.onScreenshotButtonPressed,
    this.onGraphsButtonPressed,
  });

  final ScrollController controller;

  final MethodChannel platform;
  final SharedPreferences sharedPreferences;
  final ValueNotifier<bool> homeLoadedNotifier;
  final ValueNotifier<int> platformSignalNotifier;
  final ValueNotifier<bool> debugNotifier;
  final ValueNotifier<int> updateIntervalNotifier;
  final ValueNotifier<bool> externalDatabasesNotifier;
  final ValueNotifier<bool> homeDataGraphsNotifier;
  final ValueNotifier<int> homeGraphsRetentionTimeNotifier;
  final ValueNotifier<int> currentSimSlotNotifier;

  final ValueSetter<VoidCallback>? onUpdateButtonPressed;
  final ValueSetter<VoidCallback>? onScreenshotButtonPressed;
  final ValueSetter<VoidCallback>? onGraphsButtonPressed;

  @override
  State<HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> {
  late ScrollController controller;

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

  final ValueNotifier<int> _graphsUpdateNotifier = ValueNotifier(0);
  final Map<int, Map<String, List<GraphPoint>>> _graphHistory = {};
  final Map<int, Map<String, ({String label, String unit})>> _graphInfo = {};

  late AppLocalizations _appLocalizations;

  int _simCount = 0;
  String _debug = "";
  String _plmn = "";
  bool _pageLoaded = false;

  SIMData? _simData;
  int _factor = 1;

  final Map<int, String> _cellDescriptions = {};
  final Map<int, ({int cid, bool strongMatch})> _guessedCids = {};

  String? _lastCellExistsPlmn;
  int? _lastCellExistsCid;
  bool _lastCellExistsResult = false;

  String? _guessCachePlmn;
  final Map<String, ({int cid, String description, bool strongMatch})?>
  _guessCache = {};

  @override
  void initState() {
    super.initState();
    _appLocalizations = AppLocalizations.of(context)!;

    controller = widget.controller;

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
    widget.onGraphsButtonPressed?.call(_openGraphsSheet);

    startTimer();

    widget.platformSignalNotifier.addListener(restartTimer);
    widget.updateIntervalNotifier.addListener(restartTimer);
  }

  @override
  void dispose() {
    widget.onUpdateButtonPressed?.call(() {});
    widget.onScreenshotButtonPressed?.call(() {});
    widget.onGraphsButtonPressed?.call(() {});
    timer.cancel();

    widget.platformSignalNotifier.removeListener(restartTimer);
    widget.updateIntervalNotifier.removeListener(restartTimer);

    _isUpdatingNotifier.dispose();
    _altCellViewNotifier.dispose();
    _graphsUpdateNotifier.dispose();

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

      _guessedCids.clear();

      if (_guessCachePlmn != _plmn) {
        _guessCache.clear();
        _guessCachePlmn = _plmn;
      }

      final int? primaryCid = node;
      final bool primaryHasOwnCid =
          primaryCid != null &&
          isValidString(simData.primaryCell.cellIdentifier) &&
          primaryCid != 0;

      bool primaryConfirmed = false;

      if (widget.externalDatabasesNotifier.value &&
          _plmn.isNotEmpty &&
          primaryHasOwnCid) {
        if (_lastCellExistsPlmn == _plmn && _lastCellExistsCid == primaryCid) {
          primaryConfirmed = _lastCellExistsResult;
        } else {
          primaryConfirmed = await CellDatabase.cellExists(_plmn, primaryCid);
          _lastCellExistsPlmn = _plmn;
          _lastCellExistsCid = primaryCid;
          _lastCellExistsResult = primaryConfirmed;
        }
      }

      if (primaryConfirmed) {
        final int confirmedPrimaryCid = primaryCid!;
        final int primaryNode = confirmedPrimaryCid ~/ _factor;
        final int primaryLastDigit = confirmedPrimaryCid % 10;

        for (int i = 0; i < simData.activeCells.length; i++) {
          final CellData cell = simData.activeCells[i];

          final int? ownCid = int.tryParse(cell.cellIdentifier);
          final bool hasOwnCid =
              ownCid != null &&
              isValidString(cell.cellIdentifier) &&
              ownCid != 0;

          if (hasOwnCid || !isValidInt(cell.channelNumber)) {
            continue;
          }

          final String cacheKey =
              "${cell.channelNumber}-$primaryNode-$primaryLastDigit";

          final guess = _guessCache.containsKey(cacheKey)
              ? _guessCache[cacheKey]
              : await CellDatabase.guessActiveCellCid(
                  plmn: _plmn,
                  channelNumber: cell.channelNumber,
                  targetFactor: conversionFactor(cell),
                  primaryNode: primaryNode,
                  primaryLastDigit: primaryLastDigit,
                );

          _guessCache[cacheKey] = guess;

          if (guess != null) {
            _guessedCids[i] = (cid: guess.cid, strongMatch: guess.strongMatch);
            if (guess.description.isNotEmpty) {
              _cellDescriptions[guess.cid] = guess.description;
            }
          }
        }
      }

      if (widget.homeDataGraphsNotifier.value) {
        _recordGraphData(simData.primaryCell);
      }

      _graphsUpdateNotifier.value++;

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
      controller: controller,
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
                          isActive: true,
                          descriptions: widget.externalDatabasesNotifier.value
                              ? _cellDescriptions
                              : {},
                          guessedCids: widget.externalDatabasesNotifier.value
                              ? _guessedCids
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
                  isActive: false,
                  descriptions: widget.externalDatabasesNotifier.value
                      ? _cellDescriptions
                      : {},
                  guessedCids: const {},
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

  void _recordGraphData(CellData primaryCell) {
    final int simSlot = widget.currentSimSlotNotifier.value;
    final int dataRetentionTime = widget.homeGraphsRetentionTimeNotifier.value;
    final DateTime now = DateTime.now();
    final DateTime timeDiff = now.subtract(
      Duration(seconds: dataRetentionTime),
    );

    final Map<String, List<GraphPoint>> history = _graphHistory.putIfAbsent(
      simSlot,
      () => {},
    );
    final Map<String, ({String label, String unit})> meta = _graphInfo
        .putIfAbsent(simSlot, () => {});

    final List<(String key, String label, String unit, int value)> values = [
      ("rawSignal", primaryCell.rawSignalString, "dBm", primaryCell.rawSignal),
      (
        "processedSignal",
        primaryCell.processedSignalString,
        "dBm",
        primaryCell.processedSignal,
      ),
      (
        "signalQuality",
        primaryCell.signalQualityString,
        "dB",
        primaryCell.signalQuality,
      ),
      (
        "signalNoise",
        primaryCell.signalNoiseString,
        "dB",
        primaryCell.signalNoise,
      ),
      (
        "timingAdvance",
        primaryCell.timingAdvanceString,
        "",
        primaryCell.timingAdvance,
      ),
    ];

    for (final (key, label, unit, value) in values) {
      if (!isValidString(label) || !isValidInt(value)) continue;

      meta[key] = (label: label, unit: unit);

      final List<GraphPoint> series = history.putIfAbsent(key, () => []);
      series.add(GraphPoint(time: now, value: value.toDouble()));
      series.removeWhere((p) => p.time.isBefore(timeDiff));
    }

    history.removeWhere((key, series) {
      series.removeWhere((p) => p.time.isBefore(timeDiff));

      if (series.isEmpty) {
        meta.remove(key);
        return true;
      }

      return false;
    });
  }

  List<GraphMetric> _buildGraphMetrics() {
    final int simSlot = widget.currentSimSlotNotifier.value;
    final Map<String, List<GraphPoint>> history =
        _graphHistory[simSlot] ?? const {};
    final Map<String, ({String label, String unit})> meta =
        _graphInfo[simSlot] ?? const {};

    const List<String> order = [
      "rawSignal",
      "processedSignal",
      "signalQuality",
      "signalNoise",
      "timingAdvance",
    ];

    final List<GraphMetric> graphMetrics = [];

    for (String metric in order) {
      final List<GraphPoint>? series = history[metric];
      final ({String label, String unit})? info = meta[metric];

      if (series == null || series.isEmpty || info == null) continue;

      final int latest = series.last.value.toInt();
      final String displayValue = info.unit.isEmpty
          ? "$latest"
          : "$latest${info.unit}";

      graphMetrics.add(
        GraphMetric(
          label: info.label,
          displayValue: displayValue,
          history: List.unmodifiable(series),
        ),
      );
    }

    return graphMetrics;
  }

  void _openGraphsSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (BuildContext context) {
        return GraphsModal(
          graphsUpdateNotifier: _graphsUpdateNotifier,
          dataRetentionSeconds: widget.homeGraphsRetentionTimeNotifier.value,
          metricsBuilder: _buildGraphMetrics,
        );
      },
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
