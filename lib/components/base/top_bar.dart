import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:netmanager/components/dialogs/error.dart';
import 'package:netmanager/components/dialogs/event_log.dart';
import 'package:netmanager/components/dialogs/info_modal.dart';
import 'package:netmanager/types/device/data.dart';
import 'package:netmanager/types/events/mobile_netmanager_event.dart';
import 'package:netmanager/types/events/netmanager_event.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TopBar extends StatefulWidget implements PreferredSizeWidget {
  const TopBar(
    this.platform,
    this.sharedPreferences,
    this.platformSignalNotifier,
    this.logsNotifier, {
    super.key,
  });

  final MethodChannel platform;
  final SharedPreferences sharedPreferences;
  final ValueNotifier<int> platformSignalNotifier;
  final ValueNotifier<bool> logsNotifier;

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
  late ValueNotifier<bool> logsNotifier;

  final ValueNotifier<String> title = ValueNotifier("NetManager is loading...");
  String _carrier = "NetManager";
  String _plmn = "00000";
  int _gen = 0;
  int simCount = 0;

  @override
  void initState() {
    super.initState();
    platform = widget.platform;
    sharedPreferences = widget.sharedPreferences;
    platformSignalNotifier = widget.platformSignalNotifier;
    logsNotifier = widget.logsNotifier;

    startTimer();
    platformSignalNotifier.addListener(() => restartTimer());
    logsNotifier.addListener(() {
      if (mounted) setState(() {});
    });

    checkSimCount();
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  Future<void> checkSimCount() async {
    final count = await platform.invokeMethod("getSimCount") ?? 0;
    if (mounted && count != simCount) setState(() => simCount = count);
  }

  Future<void> update() async {
    final initialTitle = title.value;

    try {
      _carrier =
          (await platform.invokeMethod<String>("getCarrier")) ?? "Unknown";
      _plmn = (await platform.invokeMethod<String>("getPlmn")) ?? "00000";
      _gen = await platform.invokeMethod<int>("getNetworkGen") as int;

      if (_gen > 0 && _plmn != "00000" && _carrier.trim().isNotEmpty) {
        title.value = "${"$_carrier $_gen"}G ($_plmn)";
      } else {
        title.value = "No service";
      }
    } on PlatformException catch (e) {
      await Sentry.captureException(e, stackTrace: e.stacktrace);
    }
  }

  void switchSim() async {
    await platform.invokeMethod("switchSim");
  }

  void openInfo() async {
    String? rawDeviceData = sharedPreferences.getString("deviceData");
    if (rawDeviceData == null) {
      await platform.invokeMethod("openRadioInfo");
      return;
    }

    final Map<String, dynamic> map = json.decode(rawDeviceData);
    late final DeviceData deviceData;

    try {
      deviceData = DeviceData.fromJson(map);
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return errorDialog(context, e);
        },
      );

      return;
    }

    if (deviceData.manufacturer.toLowerCase().trim() == "samsung") {
      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        builder: (BuildContext context) {
          return infoModal(context, platform);
        },
      );
    } else {
      await platform.invokeMethod("openRadioInfo");
    }
  }

  void openLogs() async {
    try {
      final String logs = await platform.invokeMethod("getEvents");
      if (logs.trim().isEmpty) return;

      final List<dynamic> jsonList = json.decode(logs);
      final List<NetmanagerEvent> events = jsonList.map<NetmanagerEvent>((e) {
        if (e.containsKey("simSlot") && e.containsKey("network")) {
          return MobileNetmanagerEvent.fromJson(e);
        } else {
          return NetmanagerEvent.fromJson(e);
        }
      }).toList();

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return eventLogDialog(context, events, platform);
        },
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return errorDialog(context, e);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: title,
      builder: (context, title, _) => AppBar(
        title: Text(title),
        actions: [
          IconButton(
            onPressed: openInfo,
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: "Radio info settings",
          ),
          if (simCount > 1)
            IconButton(
              onPressed: switchSim,
              icon: const Icon(Icons.sim_card_outlined),
              tooltip: "Switch SIM card",
            ),
          if (widget.logsNotifier.value)
            IconButton(
              onPressed: openLogs,
              icon: const Icon(Icons.my_library_books_outlined),
              tooltip: "Event logs",
            ),
        ],
      ),
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
    if (timer.isActive) timer.cancel();
    startTimer();
  }
}
