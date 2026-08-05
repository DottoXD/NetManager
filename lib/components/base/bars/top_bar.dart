import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:netmanager/components/dialogs/error.dart';
import 'package:netmanager/components/dialogs/event_log.dart';
import 'package:netmanager/components/modals/info_modal.dart';
import 'package:netmanager/l10n/app_localizations.dart';
import 'package:netmanager/types/base/info_menu_option.dart';
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
    this.logsNotifier,
    this.currentSimSlotNotifier,
    this.speedtestRunningNotifier, {
    super.key,
  });

  final MethodChannel platform;
  final SharedPreferences sharedPreferences;
  final ValueNotifier<int> platformSignalNotifier;
  final ValueNotifier<bool> logsNotifier;
  final ValueNotifier<int> currentSimSlotNotifier;
  final ValueNotifier<bool> speedtestRunningNotifier;

  @override
  State<TopBar> createState() => _TopBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _TopBarState extends State<TopBar> {
  late MethodChannel platform;
  late SharedPreferences sharedPreferences;
  late ValueNotifier<int> platformSignalNotifier;
  late ValueNotifier<bool> logsNotifier;
  late ValueNotifier<int> currentSimSlotNotifier;
  late ValueNotifier<bool> speedtestRunningNotifier;

  late Timer _timer;
  String _carrier = "Unknown";
  String _plmn = "00000";
  int _gen = 0;
  bool _isEmergency = false;
  int simCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    platform = widget.platform;
    sharedPreferences = widget.sharedPreferences;
    platformSignalNotifier = widget.platformSignalNotifier;
    logsNotifier = widget.logsNotifier;
    currentSimSlotNotifier = widget.currentSimSlotNotifier;
    speedtestRunningNotifier = widget.speedtestRunningNotifier;

    platformSignalNotifier.addListener(_restartTimer);

    _startTimer();
    _init();
  }

  @override
  void dispose() {
    widget.platformSignalNotifier.removeListener(_restartTimer);

    _timer.cancel();

    super.dispose();
  }

  Future<void> _init() async {
    final count = await platform.invokeMethod("getSimCount") ?? 0;
    if (mounted && count != simCount) setState(() => simCount = count);

    if (count > 0) {
      final activeSelected =
          await platform.invokeMethod("isActiveSubscriptionSelected") ?? true;

      if (!activeSelected) _switchSim();
    }
  }

  Future<void> update() async {
    try {
      _carrier =
          (await platform.invokeMethod<String>("getCarrier")) ?? "Unknown";
      _plmn = (await platform.invokeMethod<String>("getPlmn")) ?? "00000";
      _gen = await platform.invokeMethod<int>("getNetworkGen") ?? -1;
      _isEmergency =
          await platform.invokeMethod<bool>("getEmergencyOnly") ?? false;

      if (!mounted) return;

      setState(() {
        _carrier;
        _plmn;
        _gen;
        _isEmergency;
        _isLoading = false;
      });
    } on PlatformException catch (e) {
      await Sentry.captureException(
        e,
        stackTrace: e.stacktrace,
        message: SentryMessage(e.message ?? ""),
      );
    }
  }

  void _switchSim() async {
    if (speedtestRunningNotifier.value) return;

    await platform.invokeMethod("switchSim");
    await update();

    platformSignalNotifier.value++;
    currentSimSlotNotifier.value = currentSimSlotNotifier.value == 0 ? 1 : 0;
  }

  void _openInfo(AppLocalizations appLocalizations) async {
    await sharedPreferences.reload();

    String? rawDeviceData = sharedPreferences.getString("deviceData");
    if (rawDeviceData == null) {
      await platform.invokeMethod("openRadioInfo");
      return;
    }

    final device = json.decode(rawDeviceData);
    if (device is! Map<String, dynamic>) {
      return;
    }

    final Map<String, dynamic> map = device;
    late final DeviceData deviceData;

    try {
      deviceData = DeviceData.fromJson(map);
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return ErrorDialog(e: "${appLocalizations.topBar}: $e");
          },
        );
      }

      return;
    }

    final menuOptions = _resolveMenuOptions(deviceData);
    if (!mounted) return;

    if (menuOptions.length <= 1) {
      await platform.invokeMethod(menuOptions.first.method);
    } else {
      showModalBottomSheet(
        context: context,
        showDragHandle: true,
        useSafeArea: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        builder: (BuildContext context) {
          return InfoModal(platform: platform, options: menuOptions);
        },
      );
    }
  }

  void _openLogs(AppLocalizations appLocalizations) async {
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

      if (events.isEmpty) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return ErrorDialog(e: appLocalizations.noEvents);
          },
        );

        return;
      }

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return EventLogDialog(events: events, platform: platform);
        },
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return ErrorDialog(e: "${appLocalizations.topBar}: $e");
        },
      );
    }
  }

  List<InfoMenuOption> _resolveMenuOptions(DeviceData? deviceData) {
    final List<InfoMenuOption> options = [
      const InfoMenuOption(
        title: "Radio Info",
        icon: Icons.settings_input_antenna_outlined,
        method: "openRadioInfo",
      ),
    ];

    if (deviceData == null) return options;

    final manufacturer = deviceData.manufacturer.toLowerCase().trim();
    final modem = deviceData.modem.toLowerCase().trim();

    if (manufacturer == "samsung") {
      options.add(
        const InfoMenuOption(
          title: "Samsung ServiceMode",
          icon: Icons.engineering_outlined,
          method: "openSamsungInfo",
        ),
      );
    }

    if (modem.startsWith("mt") || manufacturer == "mediatek") {
      options.add(
        const InfoMenuOption(
          title: "MTK Engineer Mode",
          icon: Icons.build_circle_outlined,
          method: "openMediatekInfo",
        ),
      );
    }

    if (manufacturer == "huawei" || manufacturer == "honor") {
      options.add(
        const InfoMenuOption(
          title: "Huawei ProjectMenu",
          icon: Icons.analytics_outlined,
          method: "openHuaweiInfo",
        ),
      );
    }

    if (manufacturer == "xiaomi" ||
        manufacturer == "redmi" ||
        manufacturer == "poco") {
      options.add(
        const InfoMenuOption(
          title: "MIUI BandMode",
          icon: Icons.cell_tower_outlined,
          method: "openXiaomiInfo",
        ),
      );
    }

    return options;
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations appLocalizations = AppLocalizations.of(context)!;

    String titleText;
    if (_isLoading) {
      titleText = appLocalizations.topBarLoading;
    } else {
      String displayCarrier = (_carrier == "Unknown" || _carrier.trim().isEmpty)
          ? appLocalizations.unknown
          : _carrier;

      if (_isEmergency) {
        String genString = _gen > 0 ? "${_gen}G " : "";

        if (displayCarrier == "NetManager" && _plmn != "00000") {
          displayCarrier = _plmn;
        }

        titleText = "$displayCarrier $genString(Emergency only)";
      } else if (_gen > 0 &&
          _carrier != "Unknown" &&
          _carrier.trim().isNotEmpty) {
        String extraData = _plmn;
        titleText = "$displayCarrier ${_gen}G ($extraData)";
      } else {
        titleText = appLocalizations.noService;
      }
    }

    return AppBar(
      title: Text(titleText),
      actions: [
        IconButton(
          onPressed: () => _openInfo(appLocalizations),
          icon: const Icon(Icons.info_outlined),
          tooltip: appLocalizations.radioInfoSettings,
        ),
        if (simCount > 1)
          ValueListenableBuilder(
            valueListenable: speedtestRunningNotifier,
            builder: (context, isTestRunning, _) {
              return IconButton(
                onPressed: isTestRunning ? null : _switchSim,
                icon: const Icon(Icons.sim_card_outlined),
                tooltip: appLocalizations.switchSim,
              );
            },
          ),
        ValueListenableBuilder(
          valueListenable: logsNotifier,
          builder: (context, showLogs, _) {
            if (!showLogs) return const SizedBox.shrink();

            return IconButton(
              onPressed: () => _openLogs(appLocalizations),
              icon: const Icon(Icons.my_library_books_outlined),
              tooltip: appLocalizations.eventLogs,
            );
          },
        ),
      ],
    );
  }

  void _startTimer() {
    update();

    final interval = sharedPreferences.getInt("updateInterval") ?? 3;

    _timer = Timer.periodic(Duration(seconds: interval), (Timer t) => update());
  }

  void _restartTimer() {
    if (_timer.isActive) _timer.cancel();
    _startTimer();
  }
}
