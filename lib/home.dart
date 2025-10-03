import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:netmanager/components/body/map.dart';
import 'package:netmanager/components/body/settings.dart';
import 'package:netmanager/components/floating/position_button.dart';
import 'package:netmanager/components/base/top_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'components/body/home.dart';
import 'components/floating/update_button.dart';
import 'components/base/nav_bar.dart';

class Home extends StatefulWidget {
  const Home(
    this.sharedPreferences,
    this.dynamicThemeNotifier,
    this.themeColorNotifier,
    this.platform, {
    super.key,
  });
  final SharedPreferences sharedPreferences;
  final ValueNotifier<bool> dynamicThemeNotifier;
  final ValueNotifier<int> themeColorNotifier;
  final MethodChannel platform;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _currentPage = 0;
  late List<Widget> _pages;
  final ValueNotifier<bool> homeLoadedNotifier = ValueNotifier(false);
  final ValueNotifier<int> platformSignalNotifier = ValueNotifier(0);

  final ValueNotifier<bool> debugNotifier = ValueNotifier(false);
  final ValueNotifier<bool> logsNotifier = ValueNotifier(false);

  VoidCallback? _homeUpdateCallback;
  VoidCallback? _mapPositionCallback;

  @override
  void initState() {
    super.initState();

    widget.platform.setMethodCallHandler((call) {
      if (call.method == "restartTimer") {
        platformSignalNotifier.value = Random().nextInt(100000);
        return Future.value();
      }

      return Future.value();
    });

    debugNotifier.value = widget.sharedPreferences.getBool("debug") ?? false;
    logsNotifier.value = widget.sharedPreferences.getBool("logEvents") ?? false;

    _pages = [
      HomeBody(
        widget.platform,
        widget.sharedPreferences,
        homeLoadedNotifier,
        platformSignalNotifier,
        debugNotifier,
        onUpdateButtonPressed: (callback) {
          _homeUpdateCallback = callback;
        },
      ),
      MapBody(
        widget.platform,
        widget.sharedPreferences,
        onPositionButtonPressed: (callback) {
          _mapPositionCallback = callback;
        },
      ),
      SettingsBody(
        widget.platform,
        widget.sharedPreferences,
        widget.dynamicThemeNotifier,
        widget.themeColorNotifier,
        debugNotifier,
        logsNotifier,
      ),
    ];

    try {
      widget.platform.invokeMethod<bool>("checkPermissions");
      widget.platform.invokeMethod<void>("sendNotification");
    } on PlatformException catch (_) {
      //super error, handle it
    }
  }

  void updatePage(int page) {
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
        body: _pages[_currentPage],
        floatingActionButton: Container(
          margin: EdgeInsets.only(bottom: 15.0),
          child: (_currentPage == 0
              ? UpdateButton(onPressed: _homeUpdateCallback)
              : (_currentPage == 1
                    ? PositionButton(onPressed: _mapPositionCallback)
                    : null)),
        ),
      ),
    );
  }
}
