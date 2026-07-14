import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:netmanager/base/stack.dart';
import 'package:netmanager/components/base/body/map/map.dart';
import 'package:netmanager/components/base/body/settings/settings.dart';
import 'package:netmanager/components/base/body/speedtest/speedtest.dart';
import 'package:netmanager/components/floating/position_button.dart';
import 'package:netmanager/components/base/bars/top_bar.dart';
import 'package:netmanager/components/floating/record_button.dart';
import 'package:netmanager/components/floating/screenshot_button.dart';
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
    this.themeColorNotifier,
    this.material3Notifier,
    this.darkThemeNotifier,
    this.localeNotifier,
    this.platform, {
    super.key,
  });
  final SharedPreferences sharedPreferences;
  final ValueNotifier<bool> dynamicThemeNotifier;
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

  final ValueNotifier<int> _updateIntervalNotifier = ValueNotifier(3);
  final ValueNotifier<bool> _metricSystemNotifier = ValueNotifier(true);
  final ValueNotifier<String> _mapTilesTemplateNotifier = ValueNotifier(
    "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
  );
  final ValueNotifier<int> _speedMeasurementUnitNotifier = ValueNotifier(1);
  final ValueNotifier<String> _speedtestInstanceNotifier = ValueNotifier(
    "https://librespeed.org",
  );
  final ValueNotifier<bool> _externalDatabasesNotifier = ValueNotifier(true);
  final ValueNotifier<bool> _databaseCellsInMapNotifier = ValueNotifier(true);
  final ValueNotifier<bool> _bearingLineNotifier = ValueNotifier(true);

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
        widget.sharedPreferences.getString("speedtestInstance") ??
        "https://librespeed.org";
    _externalDatabasesNotifier.value =
        widget.sharedPreferences.getBool("externalDatabases") ?? true;
    _databaseCellsInMapNotifier.value =
        widget.sharedPreferences.getBool("databaseCellsInMap") ?? true;
    _bearingLineNotifier.value =
        widget.sharedPreferences.getBool("bearingLine") ?? true;

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

    _updateIntervalNotifier.dispose();
    _metricSystemNotifier.dispose();
    _mapTilesTemplateNotifier.dispose();
    _speedMeasurementUnitNotifier.dispose();
    _speedtestInstanceNotifier.dispose();
    _externalDatabasesNotifier.dispose();
    _databaseCellsInMapNotifier.dispose();
    _bearingLineNotifier.dispose();

    super.dispose();
  }

  void updatePage(int page) {
    if (_currentPage == page) return;

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
        ),
        bottomNavigationBar: NavBar(updatePage, _currentPage),
        body: LazyIndexedStack(
          index: _currentPage,
          children: [
            HomeBody(
              widget.platform,
              widget.sharedPreferences,
              _homeLoadedNotifier,
              _platformSignalNotifier,
              _debugNotifier,
              _updateIntervalNotifier,
              _externalDatabasesNotifier,
              onUpdateButtonPressed: (callback) {
                _homeUpdateNotifier.value = callback;
              },
              onScreenshotButtonPressed: (callback) {
                _screenshotNotifier.value = callback;
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
            ),
            SettingsBody(
              widget.platform,
              widget.sharedPreferences,
              widget.dynamicThemeNotifier,
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
                ValueListenableBuilder(
                  valueListenable: _homeUpdateNotifier,
                  builder: (context, callback, _) =>
                      UpdateButton(onPressed: callback),
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
              ],
            ],
          ),
        ),
      ),
    );
  }
}
