import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TopBar extends StatefulWidget implements PreferredSizeWidget {
  const TopBar(this.platform, this.sharedPreferences, {super.key});
  final MethodChannel platform;
  final SharedPreferences sharedPreferences;

  @override
  State<TopBar> createState() => _TopBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _TopBarState extends State<TopBar> {
  late MethodChannel platform;
  late SharedPreferences sharedPreferences;

  String _title = "NetManager is loading...";
  String _carrier = "NetManager";
  int _gen = 0;

  @override
  void initState() {
    super.initState();
    platform = widget.platform;
    sharedPreferences = widget.sharedPreferences;

    Timer updateTimer = Timer.periodic(
      Duration(seconds: sharedPreferences.getInt("updateInterval") ?? 3),
      (Timer t) => update(),
    ); //i should make it so that changing the settings restarts it
  }

  void update() {
    try {
      () async {
        _carrier = (await platform.invokeMethod<String>("getCarrier"))!;
        _gen = await platform.invokeMethod<int>("getNetworkGen") as int;
      }();

      if (_gen > 0) {
        _title = "${"$_carrier $_gen"}G";
      } else {
        _title = "No service";
      }

      setState(() {
        _title;
      });
    } on PlatformException catch (_) {
      //super error, handle it
    }
  }

  void switchSim() {
    () async {
      await platform.invokeMethod("switchSim");
    }();
  }

  void openRadioInfo() {
    () async {
      await platform.invokeMethod("openRadioInfo");
    }();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(_title),
      actions: [
        IconButton(onPressed: openRadioInfo, icon: Icon(Icons.info)),
        IconButton(onPressed: switchSim, icon: Icon(Icons.menu)),
      ],
    );
  }
}
