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
  const Home(this.sharedPreferences, this.dynamicThemeNotifier, {super.key});
  final SharedPreferences sharedPreferences;
  final ValueNotifier<bool> dynamicThemeNotifier;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  static const platform = MethodChannel('pw.dotto.netmanager/telephony');

  int _currentPage = 0;
  late List<Widget> _pages;
  final ValueNotifier<bool> homeLoadedNotifier = ValueNotifier(false);
  final ValueNotifier<int> platformSignalNotifier = ValueNotifier(0);
  final ValueNotifier<bool> debugNotifier = ValueNotifier(false);

  @override
  void initState() {
    super.initState();

    platform.setMethodCallHandler((call) {
      if (call.method == "restartTimer") {
        platformSignalNotifier.value = Random().nextInt(100000);
        return Future.value();
      }

      return Future.value();
    });

    debugNotifier.value = widget.sharedPreferences.getBool("debug") ?? false;

    _pages = [
      HomeBody(
        platform,
        widget.sharedPreferences,
        homeLoadedNotifier,
        platformSignalNotifier,
        debugNotifier,
      ),
      MapBody(platform, widget.sharedPreferences),
      SettingsBody(
        platform,
        widget.sharedPreferences,
        widget.dynamicThemeNotifier,
        debugNotifier,
      ),
    ];

    try {
      platform.invokeMethod<bool>("checkPermissions");
      platform.invokeMethod<void>("sendNotification");
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
          platform,
          widget.sharedPreferences,
          platformSignalNotifier,
        ),
        bottomNavigationBar: NavBar(updatePage, _currentPage),
        body: _pages[_currentPage],
        floatingActionButton: (_currentPage == 0
            ? UpdateButton()
            : (_currentPage == 1 ? PositionButton() : null)),
      ),
    );
  }
}
