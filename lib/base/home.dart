import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:netmanager/base/stack.dart';
import 'package:netmanager/components/base/body/map/map.dart';
import 'package:netmanager/components/base/body/settings/settings.dart';
import 'package:netmanager/components/base/body/speedtest/speedtest.dart';
import 'package:netmanager/components/floating/graphs_button.dart';
import 'package:netmanager/components/floating/history_button.dart';
import 'package:netmanager/components/floating/position_button.dart';
import 'package:netmanager/components/base/bars/top_bar.dart';
import 'package:netmanager/components/floating/record_button.dart';
import 'package:netmanager/components/floating/screenshot_button.dart';
import 'package:netmanager/components/floating/share_button.dart';
import 'package:netmanager/types/device/permissions.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../components/base/body/home/home.dart';
import '../components/floating/update_button.dart';
import '../components/base/bars/nav_bar.dart';

class Home extends StatefulWidget {
  const Home(
    this.sharedPreferences,
    this.dynamicThemeNotifier,
    this.harmonizedColorsNotifier,
    this.themeColorNotifier,
    this.material3Notifier,
    this.darkThemeNotifier,
    this.localeNotifier,
    this.platform, {
    super.key,
  });
  final SharedPreferences sharedPreferences;
  final ValueNotifier<bool> dynamicThemeNotifier;
  final ValueNotifier<bool> harmonizedColorsNotifier;
  final ValueNotifier<int> themeColorNotifier;
  final ValueNotifier<bool> material3Notifier;
  final ValueNotifier<bool> darkThemeNotifier;
  final ValueNotifier<Locale?> localeNotifier;
  final MethodChannel platform;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _currentPage = 0;
  final ValueNotifier<bool> _homeLoadedNotifier = ValueNotifier(false);
  final ValueNotifier<int> _platformSignalNotifier = ValueNotifier(0);

  final ValueNotifier<bool> _debugNotifier = ValueNotifier(false);
  final ValueNotifier<bool> _logsNotifier = ValueNotifier(false);

  final ValueNotifier<bool> _recordingActionNotifier = ValueNotifier(false);

  final ValueNotifier<VoidCallback?> _homeUpdateNotifier = ValueNotifier(null);
  final ValueNotifier<VoidCallback?> _screenshotNotifier = ValueNotifier(null);
  final ValueNotifier<VoidCallback?> _mapPositionNotifier = ValueNotifier(null);
  final ValueNotifier<VoidCallback?> _recordNotifier = ValueNotifier(null);
  final ValueNotifier<VoidCallback?> _graphsNotifier = ValueNotifier(null);
  final ValueNotifier<VoidCallback?> _historyNotifier = ValueNotifier(null);
  final ValueNotifier<VoidCallback?> _shareResultNotifier = ValueNotifier(null);
  final ValueNotifier<bool> _canShareResultNotifier = ValueNotifier(false);

  final ValueNotifier<int> _updateIntervalNotifier = ValueNotifier(3);
  final ValueNotifier<bool> _metricSystemNotifier = ValueNotifier(true);
  final ValueNotifier<String> _mapTilesTemplateNotifier = ValueNotifier(
    "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
  );
  final ValueNotifier<int> _speedMeasurementUnitNotifier = ValueNotifier(1);
  final ValueNotifier<String> _speedtestInstanceNotifier = ValueNotifier("");
  final ValueNotifier<bool> _externalDatabasesNotifier = ValueNotifier(true);
  final ValueNotifier<bool> _databaseCellsInMapNotifier = ValueNotifier(true);
  final ValueNotifier<bool> _bearingLineNotifier = ValueNotifier(true);

  final ValueNotifier<bool> _homeDataGraphsNotifier = ValueNotifier(true);
  final ValueNotifier<int> _homeGraphsRetentionTimeNotifier = ValueNotifier(30);

  final ValueNotifier<int> _currentSimSlotNotifier = ValueNotifier(0);
  final ValueNotifier<bool> _speedtestRunningNotifier = ValueNotifier(false);

  final ScrollController _homeScrollController = ScrollController();
  final ScrollController _settingsScrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    _cleanOldExports();

    widget.platform.setMethodCallHandler((call) {
      if (call.method == "restartTimer") {
        _platformSignalNotifier.value++;
      }

      return Future.value();
    });

    _debugNotifier.value = widget.sharedPreferences.getBool("debug") ?? false;
    _logsNotifier.value =
        widget.sharedPreferences.getBool("logEvents") ?? false;

    _updateIntervalNotifier.value =
        widget.sharedPreferences.getInt("updateInterval") ?? 3;
    _metricSystemNotifier.value =
        widget.sharedPreferences.getBool("metricSystem") ?? true;
    _mapTilesTemplateNotifier.value =
        widget.sharedPreferences.getString("mapTilesTemplate") ??
        "https://tile.openstreetmap.org/{z}/{x}/{y}.png";
    _speedMeasurementUnitNotifier.value =
        widget.sharedPreferences.getInt("speedMeasurementUnit") ?? 1;
    _speedtestInstanceNotifier.value =
        widget.sharedPreferences.getString("speedtestInstance") ?? "";
    _externalDatabasesNotifier.value =
        widget.sharedPreferences.getBool("externalDatabases") ?? true;
    _databaseCellsInMapNotifier.value =
        widget.sharedPreferences.getBool("databaseCellsInMap") ?? true;
    _bearingLineNotifier.value =
        widget.sharedPreferences.getBool("bearingLine") ?? true;
    _homeDataGraphsNotifier.value =
        widget.sharedPreferences.getBool("homeDataGraphs") ?? true;
    _homeGraphsRetentionTimeNotifier.value =
        widget.sharedPreferences.getInt("homeGraphsRetentionTime") ?? 30;

    try {
      widget.platform.invokeMethod<bool>("requestPermissions", {
        "perms":
            Permissions.READ_PHONE_STATE |
            Permissions.ACCESS_FINE_LOCATION |
            Permissions.ACCESS_BACKGROUND_LOCATION,
      });
      widget.platform.invokeMethod<void>("sendNotification");
    } on PlatformException catch (e) {
      Sentry.captureException(e, stackTrace: e.stacktrace);
    }
  }

  Future<void> _cleanOldExports() async {
    final tempDir = await getTemporaryDirectory();
    final exportDir = Directory("${tempDir.path}/exports");

    if (exportDir.existsSync()) {
      await exportDir.delete(recursive: true);
    }
  }

  @override
  void dispose() {
    widget.platform.setMethodCallHandler(null);

    _homeLoadedNotifier.dispose();
    _platformSignalNotifier.dispose();
    _debugNotifier.dispose();
    _logsNotifier.dispose();
    _recordingActionNotifier.dispose();

    _homeUpdateNotifier.dispose();
    _screenshotNotifier.dispose();
    _mapPositionNotifier.dispose();
    _recordNotifier.dispose();
    _graphsNotifier.dispose();
    _historyNotifier.dispose();
    _shareResultNotifier.dispose();
    _canShareResultNotifier.dispose();

    _updateIntervalNotifier.dispose();
    _metricSystemNotifier.dispose();
    _mapTilesTemplateNotifier.dispose();
    _speedMeasurementUnitNotifier.dispose();
    _speedtestInstanceNotifier.dispose();
    _externalDatabasesNotifier.dispose();
    _databaseCellsInMapNotifier.dispose();
    _bearingLineNotifier.dispose();
    _homeDataGraphsNotifier.dispose();
    _homeGraphsRetentionTimeNotifier.dispose();
    _currentSimSlotNotifier.dispose();
    _speedtestRunningNotifier.dispose();

    _homeScrollController.dispose();
    _settingsScrollController.dispose();

    super.dispose();
  }

  void updatePage(int page) {
    if (_currentPage == page) {
      if (page == 0 && _homeScrollController.hasClients) {
        _homeScrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      } else if (page == 3 && _settingsScrollController.hasClients) {
        _settingsScrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }

      return;
    }

    setState(() {
      _currentPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentPage == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentPage != 0) {
          setState(() {
            _currentPage = 0;
          });
        }
      },
      child: Scaffold(
        appBar: TopBar(
          widget.platform,
          widget.sharedPreferences,
          _platformSignalNotifier,
          _logsNotifier,
          _currentSimSlotNotifier,
          _speedtestRunningNotifier,
        ),
        bottomNavigationBar: NavBar(updatePage, _currentPage),
        body: LazyIndexedStack(
          index: _currentPage,
          children: [
            HomeBody(
              _homeScrollController,
              widget.platform,
              widget.sharedPreferences,
              _homeLoadedNotifier,
              _platformSignalNotifier,
              _debugNotifier,
              _updateIntervalNotifier,
              _externalDatabasesNotifier,
              _homeDataGraphsNotifier,
              _homeGraphsRetentionTimeNotifier,
              _currentSimSlotNotifier,
              onUpdateButtonPressed: (callback) {
                _homeUpdateNotifier.value = callback;
              },
              onScreenshotButtonPressed: (callback) {
                _screenshotNotifier.value = callback;
              },
              onGraphsButtonPressed: (callback) {
                _graphsNotifier.value = callback;
              },
            ),
            MapBody(
              widget.platform,
              widget.sharedPreferences,
              _platformSignalNotifier,
              _recordingActionNotifier,
              _updateIntervalNotifier,
              _metricSystemNotifier,
              _mapTilesTemplateNotifier,
              _databaseCellsInMapNotifier,
              _externalDatabasesNotifier,
              _bearingLineNotifier,
              onPositionButtonPressed: (callback) {
                _mapPositionNotifier.value = callback;
              },
              onRecordButtonPressed: (callback) {
                _recordNotifier.value = callback;
              },
            ),
            SpeedtestBody(
              widget.platform,
              widget.sharedPreferences,
              _speedMeasurementUnitNotifier,
              _speedtestInstanceNotifier,
              _speedtestRunningNotifier,
              _canShareResultNotifier,
              onHistoryButtonPressed: (callback) {
                _historyNotifier.value = callback;
              },
              onShareResultButtonPressed: (callback) {
                _shareResultNotifier.value = callback;
              },
            ),
            SettingsBody(
              _settingsScrollController,
              widget.platform,
              widget.sharedPreferences,
              widget.dynamicThemeNotifier,
              widget.harmonizedColorsNotifier,
              widget.themeColorNotifier,
              widget.material3Notifier,
              widget.darkThemeNotifier,
              widget.localeNotifier,
              _debugNotifier,
              _logsNotifier,
              _updateIntervalNotifier,
              _metricSystemNotifier,
              _mapTilesTemplateNotifier,
              _speedMeasurementUnitNotifier,
              _speedtestInstanceNotifier,
              _externalDatabasesNotifier,
              _databaseCellsInMapNotifier,
              _bearingLineNotifier,
              _homeDataGraphsNotifier,
              _homeGraphsRetentionTimeNotifier,
            ),
          ],
        ),
        floatingActionButton: Container(
          margin: const EdgeInsets.only(bottom: 4.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (_currentPage == 0) ...[
                ValueListenableBuilder(
                  valueListenable: _screenshotNotifier,
                  builder: (context, callback, _) =>
                      ScreenshotButton(onPressed: callback),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ValueListenableBuilder(
                      valueListenable: _homeDataGraphsNotifier,
                      builder: (context, graphsEnabled, _) {
                        if (!graphsEnabled) return const SizedBox.shrink();

                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Transform.translate(
                            offset: const Offset(0, 2),
                            child: ValueListenableBuilder(
                              valueListenable: _graphsNotifier,
                              builder: (context, callback, _) =>
                                  GraphsButton(onPressed: callback),
                            ),
                          ),
                        );
                      },
                    ),
                    ValueListenableBuilder(
                      valueListenable: _homeUpdateNotifier,
                      builder: (context, callback, _) =>
                          UpdateButton(onPressed: callback),
                    ),
                  ],
                ),
              ] else if (_currentPage == 1) ...[
                ValueListenableBuilder(
                  valueListenable: _recordNotifier,
                  builder: (context, callback, _) => RecordButton(
                    onPressed: callback,
                    recordingActionNotifier: _recordingActionNotifier,
                  ),
                ),
                const SizedBox(height: 4),
                ValueListenableBuilder(
                  valueListenable: _mapPositionNotifier,
                  builder: (context, callback, _) =>
                      PositionButton(onPressed: callback),
                ),
              ] else if (_currentPage == 2) ...[
                ValueListenableBuilder(
                  valueListenable: _canShareResultNotifier,
                  builder: (context, canShare, _) {
                    if (!canShare) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        ValueListenableBuilder(
                          valueListenable: _shareResultNotifier,
                          builder: (context, callback, _) =>
                              ShareResultButton(onPressed: callback),
                        ),
                        const SizedBox(height: 4),
                      ],
                    );
                  },
                ),
                ValueListenableBuilder(
                  valueListenable: _historyNotifier,
                  builder: (context, callback, _) =>
                      HistoryButton(onPressed: callback),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
