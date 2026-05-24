import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:netmanager/components/base/body/map.dart';
import 'package:netmanager/components/base/body/settings.dart';
import 'package:netmanager/components/base/body/speedtest/speedtest.dart';
import 'package:netmanager/components/floating/position_button.dart';
import 'package:netmanager/components/base/bars/top_bar.dart';
import 'package:netmanager/components/floating/record_button.dart';
import 'package:netmanager/components/floating/screenshot_button.dart';
import 'package:netmanager/types/device/permissions.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'components/base/body/home/home.dart';
import 'components/floating/update_button.dart';
import 'components/base/bars/nav_bar.dart';

class Home extends StatefulWidget {
  const Home(
    this.sharedPreferences,
    this.dynamicThemeNotifier,
    this.themeColorNotifier,
    this.material3Notifier,
    this.platform, {
    super.key,
  });
  final SharedPreferences sharedPreferences;
  final ValueNotifier<bool> dynamicThemeNotifier;
  final ValueNotifier<int> themeColorNotifier;
  final ValueNotifier<bool> material3Notifier;
  final MethodChannel platform;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _currentPage = 0;
  final ValueNotifier<bool> homeLoadedNotifier = ValueNotifier(false);
  final ValueNotifier<int> platformSignalNotifier = ValueNotifier(0);

  final ValueNotifier<bool> debugNotifier = ValueNotifier(false);
  final ValueNotifier<bool> logsNotifier = ValueNotifier(false);

  final ValueNotifier<bool> recordingActionNotifier = ValueNotifier(false);

  final ValueNotifier<VoidCallback?> _homeUpdateNotifier = ValueNotifier(null);
  final ValueNotifier<VoidCallback?> _screenshotNotifier = ValueNotifier(null);
  final ValueNotifier<VoidCallback?> _mapPositionNotifier = ValueNotifier(null);
  final ValueNotifier<VoidCallback?> _recordNotifier = ValueNotifier(null);

  @override
  void initState() {
    super.initState();

    _cleanOldExports();

    widget.platform.setMethodCallHandler((call) {
      if (call.method == "restartTimer") {
        platformSignalNotifier.value++;
      }

      return Future.value();
    });

    debugNotifier.value = widget.sharedPreferences.getBool("debug") ?? false;
    logsNotifier.value = widget.sharedPreferences.getBool("logEvents") ?? false;

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

    homeLoadedNotifier.dispose();
    platformSignalNotifier.dispose();
    debugNotifier.dispose();
    logsNotifier.dispose();
    recordingActionNotifier.dispose();

    _homeUpdateNotifier.dispose();
    _screenshotNotifier.dispose();
    _mapPositionNotifier.dispose();
    _recordNotifier.dispose();

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
          platformSignalNotifier,
          logsNotifier,
        ),
        bottomNavigationBar: NavBar(updatePage, _currentPage),
        body: IndexedStack(
          index: _currentPage,
          children: [
            HomeBody(
              widget.platform,
              widget.sharedPreferences,
              homeLoadedNotifier,
              platformSignalNotifier,
              debugNotifier,
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
              platformSignalNotifier,
              recordingActionNotifier,
              onPositionButtonPressed: (callback) {
                _mapPositionNotifier.value = callback;
              },
              onRecordButtonPressed: (callback) {
                _recordNotifier.value = callback;
              },
            ),
            SpeedtestBody(widget.platform, widget.sharedPreferences),
            SettingsBody(
              widget.platform,
              widget.sharedPreferences,
              widget.dynamicThemeNotifier,
              widget.themeColorNotifier,
              widget.material3Notifier,
              debugNotifier,
              logsNotifier,
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
                    recordingActionNotifier: recordingActionNotifier,
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
