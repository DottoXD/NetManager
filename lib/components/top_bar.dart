import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TopBar extends StatefulWidget implements PreferredSizeWidget {
  const TopBar(
    this.platform,
    this.sharedPreferences,
    this.platformSignalNotifier, {
    super.key,
  });
  final MethodChannel platform;
  final SharedPreferences sharedPreferences;
  final ValueNotifier<int> platformSignalNotifier;

  @override
  State<TopBar> createState() => _TopBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _TopBarState extends State<TopBar> {
  late MethodChannel platform;
  late SharedPreferences sharedPreferences;
  late Timer timer;
  late ValueNotifier<int> platformSignalNotifier;

  String _title = "NetManager is loading...";
  String _carrier = "NetManager";
  String _plmn = "00000";
  int _gen = 0;

  Widget _switchSimButton = Container();
  int simCount = 0;

  Widget _logsButton = Container();

  @override
  void initState() {
    super.initState();
    platform = widget.platform;
    sharedPreferences = widget.sharedPreferences;

    bool? logEvents = sharedPreferences.getBool(
      "logEvents",
    ); //still gotta make it update with settings
    if (logEvents != null && logEvents) {
      setState(() {
        _logsButton = IconButton(
          onPressed: openLogs,
          icon: Icon(Icons.my_library_books_outlined),
          tooltip: "Event logs",
        ); //temporarily like that
      });
    }

    startTimer();

    widget.platformSignalNotifier.addListener(() {
      restartTimer();
    });

    () async {
      simCount = await platform.invokeMethod("getSimCount");
      if (simCount > 1) {
        setState(() {
          _switchSimButton = IconButton(
            onPressed: switchSim,
            icon: Icon(Icons.sim_card_outlined),
            tooltip: "Switch SIM card",
          );
        });
      }
    }();
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  Future<void> update() async {
    try {
      _carrier =
          (await platform.invokeMethod<String>("getCarrier")) ?? "Unknown";
      _plmn = (await platform.invokeMethod<String>("getPlmn")) ?? "";
      _gen = await platform.invokeMethod<int>("getNetworkGen") as int;

      if (_gen > 0 && _plmn.isNotEmpty) {
        _title = "${"$_carrier $_gen"}G ($_plmn)";
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

  void openLogs() {}

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(_title),
      actions: [
        IconButton(
          onPressed: openRadioInfo,
          icon: Icon(Icons.perm_device_info_rounded),
          tooltip: "Radio info settings",
        ),
        _switchSimButton,
        _logsButton,
      ],
    );
  }

  void startTimer() {
    update();

    timer = Timer.periodic(
      Duration(seconds: sharedPreferences.getInt("updateInterval") ?? 3),
      (Timer t) => update(),
    );
  }

  void restartTimer() {
    timer.cancel();
    startTimer();
  }
}
