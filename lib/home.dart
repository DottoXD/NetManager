import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:netmanager/components/body/map.dart';
import 'package:netmanager/components/body/settings.dart';
import 'package:netmanager/components/top_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'components/body/home.dart';
import 'components/floating_button.dart';
import 'components/nav_bar.dart';

class Home extends StatefulWidget {
  const Home(this.sharedPreferences, { super.key });
  final SharedPreferences sharedPreferences;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  static const platform = MethodChannel('it.dotto.netmanager/telephony');

  int _currentPage = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _pages = [
      HomeBody(platform, widget.sharedPreferences),
      MapBody(platform),
      SettingsBody(platform, widget.sharedPreferences)
    ];

    try {
      platform.invokeMethod<bool>('checkPermissions');
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
    return Scaffold(
        appBar: TopBar(platform),
        bottomNavigationBar: NavBar(updatePage, _currentPage),
        body: _pages[_currentPage],
        floatingActionButton: (_currentPage == 0 ? FloatingButton() : null)
    );
  }
}