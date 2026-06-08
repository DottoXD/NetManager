import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:netmanager/components/dialogs/about.dart';
import 'package:netmanager/components/dialogs/database_manager.dart';
import 'package:netmanager/components/dialogs/debug_log.dart';
import 'package:netmanager/components/dialogs/error.dart';
import 'package:netmanager/components/dialogs/position_precision.dart';
import 'package:netmanager/components/dialogs/speed_unit.dart';
import 'package:netmanager/utils/color_selection.dart';
import 'package:netmanager/utils/event_selection.dart';
import 'package:netmanager/utils/haptic_service.dart';
import 'package:netmanager/types/device/permissions.dart';
import 'package:netmanager/types/events/event_types.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsBody extends StatefulWidget {
  const SettingsBody(
    this.platform,
    this.sharedPreferences,
    this.dynamicThemeNotifier,
    this.themeColorNotifier,
    this.material3Notifier,
    this.debugNotifier,
    this.logsNotifier,
    this.updateIntervalNotifier,
    this.metricSystemNotifier,
    this.mapTilesTemplateNotifier,
    this.speedMeasurementUnitNotifier,
    this.speedtestInstanceNotifier,
    this.externalDatabasesNotifier,
    this.databaseCellsInMapNotifier, {
    super.key,
  });

  final MethodChannel platform;
  final SharedPreferences sharedPreferences;

  final ValueNotifier<bool> dynamicThemeNotifier;
  final ValueNotifier<int> themeColorNotifier;
  final ValueNotifier<bool> material3Notifier;

  final ValueNotifier<bool> debugNotifier;
  final ValueNotifier<bool> logsNotifier;

  final ValueNotifier<int> updateIntervalNotifier;
  final ValueNotifier<bool> metricSystemNotifier;
  final ValueNotifier<String> mapTilesTemplateNotifier;
  final ValueNotifier<int> speedMeasurementUnitNotifier;
  final ValueNotifier<String> speedtestInstanceNotifier;
  final ValueNotifier<bool> externalDatabasesNotifier;
  final ValueNotifier<bool> databaseCellsInMapNotifier;

  @override
  State<SettingsBody> createState() => _SettingsBodyState();
}

class _SettingsBodyState extends State<SettingsBody> {
  late MethodChannel platform;
  late SharedPreferences sharedPreferences;

  late ValueNotifier<bool> dynamicThemeNotifier;
  late ValueNotifier<int> themeColorNotifier;
  late ValueNotifier<bool> material3Notifier;

  late ValueNotifier<bool> debugNotifier;
  late ValueNotifier<bool> logsNotifier;

  late ValueNotifier<int> updateIntervalNotifier;
  late ValueNotifier<bool> metricSystemNotifier;
  late ValueNotifier<String> mapTilesTemplateNotifier;
  late ValueNotifier<int> speedMeasurementUnitNotifier;
  late ValueNotifier<String> speedtestInstanceNotifier;
  late ValueNotifier<bool> externalDatabasesNotifier;
  late ValueNotifier<bool> databaseCellsInMapNotifier;

  late TextEditingController _mapTilesTemplateController;
  late TextEditingController _speedtestInstanceController;

  final List<String> positionPrecisions = ["Off", "Low", "Medium", "High"];
  final List<String> speedMeasurementUnits = ["Gbps", "Mbps", "Kbps"];

  bool _startupMonitoring = false;
  bool _backgroundService = false;
  bool _analytics = false;
  bool _checkUpdates = false;
  bool _logEvents = false;
  bool _metricSystem = true;
  String _mapTilesTemplate = "https://tile.openstreetmap.org/{z}/{x}/{y}.png";
  int _maximumLogs = 10;
  int _updateInterval = 3;
  int _backgroundUpdateInterval = 3;
  int _positionPrecision = 3;
  int _speedMeasurementUnit = 1;
  String _speedtestInstance = "https://librespeed.org";
  bool _externalDatabases = true;
  bool _databaseCellsInMap = true;
  List<String> _importedDatabases = [];
  int _themeColor = 0xFFE6F0F2;
  bool _hapticFeedback = true;
  bool _material3 = true;
  bool _dynamicSupported = true;
  bool _dynamicTheme = true;
  bool _debug = false;

  //Temporary
  bool _useNewCore = false;

  List<EventTypes> _loggedEventTypes = EventTypes.values.toList();

  late String _positionPrecisionSelection;
  late String _speedMeasurementUnitSelection;

  @override
  void initState() {
    super.initState();
    platform = widget.platform;
    sharedPreferences = widget.sharedPreferences;
    dynamicThemeNotifier = widget.dynamicThemeNotifier;
    themeColorNotifier = widget.themeColorNotifier;
    material3Notifier = widget.material3Notifier;
    debugNotifier = widget.debugNotifier;
    logsNotifier = widget.logsNotifier;
    updateIntervalNotifier = widget.updateIntervalNotifier;
    metricSystemNotifier = widget.metricSystemNotifier;
    mapTilesTemplateNotifier = widget.mapTilesTemplateNotifier;
    speedMeasurementUnitNotifier = widget.speedMeasurementUnitNotifier;
    speedtestInstanceNotifier = widget.speedtestInstanceNotifier;
    externalDatabasesNotifier = widget.externalDatabasesNotifier;
    databaseCellsInMapNotifier = widget.databaseCellsInMapNotifier;

    updateData();
    _positionPrecisionSelection = positionPrecisions[_positionPrecision];
    _speedMeasurementUnitSelection =
        speedMeasurementUnits[_speedMeasurementUnit];

    _mapTilesTemplateController = TextEditingController(
      text: _mapTilesTemplate,
    );
    _speedtestInstanceController = TextEditingController(
      text: _speedtestInstance,
    );
  }

  @override
  void dispose() {
    _mapTilesTemplateController.dispose();
    _speedtestInstanceController.dispose();

    super.dispose();
  }

  Future<void> updateData() async {
    setState(() {
      _startupMonitoring =
          sharedPreferences.getBool("startupMonitoring") ?? _startupMonitoring;
      _backgroundService =
          sharedPreferences.getBool("backgroundService") ?? _backgroundService;
      _analytics = sharedPreferences.getBool("analytics") ?? _analytics;
      _checkUpdates =
          sharedPreferences.getBool("checkUpdates") ?? _checkUpdates;
      _logEvents = sharedPreferences.getBool("logEvents") ?? _logEvents;
      _metricSystem =
          sharedPreferences.getBool("metricSystem") ?? _metricSystem;
      _mapTilesTemplate =
          sharedPreferences.getString("mapTilesTemplate") ?? _mapTilesTemplate;
      _maximumLogs = sharedPreferences.getInt("maximumLogs") ?? _maximumLogs;
      _updateInterval =
          sharedPreferences.getInt("updateInterval") ?? _updateInterval;
      _backgroundUpdateInterval =
          sharedPreferences.getInt("backgroundUpdateInterval") ??
          _backgroundUpdateInterval;
      _positionPrecision =
          sharedPreferences.getInt("positionPrecision") ?? _positionPrecision;
      _speedMeasurementUnit =
          sharedPreferences.getInt("speedMeasurementUnit") ??
          _speedMeasurementUnit;
      _speedtestInstance =
          sharedPreferences.getString("speedtestInstance") ??
          _speedtestInstance;
      _externalDatabases =
          sharedPreferences.getBool("externalDatabases") ?? _externalDatabases;
      _databaseCellsInMap =
          sharedPreferences.getBool("databaseCellsInMap") ??
          _databaseCellsInMap;
      _importedDatabases =
          sharedPreferences.getStringList("importedDatabases") ??
          _importedDatabases;
      _material3 = sharedPreferences.getBool("material3") ?? _material3;
      _hapticFeedback =
          sharedPreferences.getBool("hapticFeedback") ?? _hapticFeedback;
      _dynamicTheme =
          sharedPreferences.getBool("dynamicTheme") ?? _dynamicTheme;
      _themeColor = sharedPreferences.getInt("themeColor") ?? _themeColor;
      _dynamicSupported =
          sharedPreferences.getBool("dynamicSupported") ?? _dynamicSupported;
      _useNewCore = sharedPreferences.getBool("useNewCore") ?? _useNewCore;

      List<String>? tempLoggedEventTypes = sharedPreferences.getStringList(
        "loggedEventTypes",
      );
      if (tempLoggedEventTypes != null) {
        _loggedEventTypes = tempLoggedEventTypes
            .map((v) => EventTypes.values.byName(v))
            .toList();
      }

      _debug = sharedPreferences.getBool("debug") ?? _debug;
    });
  }

  Future<void> onToggleStartupMonitoring(bool value) async {
    bool perms =
        await platform.invokeMethod<bool>("checkPermissions", {
          "perms": Permissions.POST_NOTIFICATIONS,
        }) ??
        false;

    bool finalValue = value;

    if (value && !perms) {
      await platform.invokeMethod<bool>("requestPermissions", {
        "perms": Permissions.POST_NOTIFICATIONS,
      });

      bool finalPerms =
          await platform.invokeMethod<bool>("checkPermissions", {
            "perms": Permissions.POST_NOTIFICATIONS,
          }) ??
          false;

      if (!finalPerms) {
        finalValue = false;
      }
    }

    setBool("startupMonitoring", finalValue);
    setState(() {
      _startupMonitoring = finalValue;
    });
  }

  Future<void> onToggleBackgroundService(bool value) async {
    bool perms =
        await platform.invokeMethod<bool>("checkPermissions", {
          "perms": Permissions.POST_NOTIFICATIONS,
        }) ??
        false;

    bool finalValue = value;

    if (value && !perms) {
      await platform.invokeMethod<bool>("requestPermissions", {
        "perms": Permissions.POST_NOTIFICATIONS,
      });

      bool finalPerms =
          await platform.invokeMethod<bool>("checkPermissions", {
            "perms": Permissions.POST_NOTIFICATIONS,
          }) ??
          false;

      if (!finalPerms) {
        finalValue = false;
      }
    }

    if (finalValue) {
      await platform.invokeMethod<void>("sendNotification");
    } else {
      await platform.invokeMethod<void>("cancelNotification");
    }

    setBool("backgroundService", finalValue);
    setState(() {
      _backgroundService = finalValue;
    });
  }

  void setBool(String key, bool value) {
    sharedPreferences.setBool(key, value);
  }

  void setInt(String key, int value) {
    sharedPreferences.setInt(key, value);
  }

  void setStringList(String key, List<String> value) {
    sharedPreferences.setStringList(key, value);
  }

  void setString(String key, String value) {
    sharedPreferences.setString(key, value);
  }

  void openDebugLogs() async {
    try {
      final String debugLogs = await platform.invokeMethod("getDebugLogs");
      if (debugLogs.trim().isEmpty) return;

      final List<String> debugLogsList =
          (json.decode(debugLogs) as List<dynamic>)
              .map((e) => e.toString())
              .toList();

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return debugLogDialog(context, debugLogsList, platform);
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
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.opaque,
      child: ListView(
        shrinkWrap: true,
        physics: ClampingScrollPhysics(),
        children: <Widget>[
          ListTile(
            title: Text("Analytics"),
            subtitle: Text(
              "Share anonymous insights to help me improve NetManager.",
            ),
            trailing: Switch(
              value: _analytics,
              onChanged: (bool value) async {
                await HapticService().triggerHaptic(
                  HapticType.SELECTION,
                  context,
                );

                setBool("analytics", value);
                updateData();
              },
            ),
          ),
          ListTile(
            title: Text("Check for updates"),
            subtitle: Text(
              "Let NetManager automatically look for updates when the app is opened.",
            ),
            trailing: Switch(
              value: _checkUpdates,
              onChanged: (bool value) async {
                await HapticService().triggerHaptic(
                  HapticType.SELECTION,
                  context,
                );

                setBool("checkUpdates", value);
                updateData();
              },
            ),
          ),
          Divider(
            height: 0,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          ListTile(
            title: Text(
              "Position precision (${positionPrecisions[_positionPrecision]})",
            ),
            subtitle: Text(
              "The precision of your position determines the precision of the map tracking service.",
            ),
            trailing: IconButton(
              icon: Icon(Icons.edit),
              onPressed: () => showDialog(
                context: context,
                builder: (BuildContext context) {
                  return positionPrecisionDialog(
                    context,
                    positionPrecisions,
                    _positionPrecisionSelection,
                    (index, value) {
                      setState(() {
                        _positionPrecisionSelection = value;
                      });

                      setInt("positionPrecision", index);
                      updateData();
                    },
                  );
                },
              ),
            ),
          ),
          ListTile(
            title: Text("Startup monitoring"),
            subtitle: Text(
              "Start the monitoring service with your device. The map tracking service still needs to be manually started in the app.",
            ),
            trailing: Switch(
              value: _startupMonitoring,
              onChanged: (bool value) async {
                await HapticService().triggerHaptic(
                  HapticType.SELECTION,
                  context,
                );

                await onToggleStartupMonitoring(value);
              },
            ),
          ),
          ListTile(
            title: Text("Background service"),
            subtitle: Text(
              "Keep the monitoring service running even when you shut down the app.",
            ),
            trailing: Switch(
              value: _backgroundService,
              onChanged: (bool value) async {
                await HapticService().triggerHaptic(
                  HapticType.SELECTION,
                  context,
                );

                await onToggleBackgroundService(value);
              },
            ),
          ),
          ListTile(
            title: Text("Update interval (${_updateInterval}s)"),
            subtitle: Text(
              "The interval in seconds between each monitoring service data update.",
            ),
          ),
          Slider(
            value: _updateInterval.toDouble(),
            max: 30,
            min: 1,
            label: _updateInterval.toString(),
            onChanged: (double value) {
              setInt("updateInterval", value.toInt());
              updateIntervalNotifier.value = value.toInt();
              updateData();
            },
          ),
          ListTile(
            title: Text(
              "Background update interval (${_backgroundUpdateInterval}s)",
            ),
            subtitle: Text(
              "The interval between each monitoring service data update when it is running in the background or on startup.",
            ),
            enabled: (_backgroundService || _startupMonitoring),
          ),
          if (_backgroundService || _startupMonitoring)
            Slider(
              value: _backgroundUpdateInterval.toDouble(),
              max: 30,
              min: 1,
              label: _backgroundUpdateInterval.toString(),
              onChanged: (double value) {
                setInt("backgroundUpdateInterval", value.toInt());
                updateData();
              },
            ),
          Divider(
            height: 0,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          ListTile(
            title: Text("Haptics"),
            subtitle: Text(
              "Haptic feedback allows the app to feel more immersive.",
            ),
            trailing: Switch(
              value: _hapticFeedback,
              onChanged: (bool value) async {
                await HapticService().setHapticEnabled(value);
                if (context.mounted) {
                  await HapticService().triggerHaptic(
                    HapticType.SELECTION,
                    context,
                  );
                }

                setBool("hapticFeedback", value);
                updateData();
              },
            ),
          ),
          ListTile(
            title: Text("Material You (3)"),
            subtitle: Text(
              "Use Material You, Android's latest UI kit. Do note that Material 2 is not well unsupported.",
            ),
            trailing: Switch(
              value: _material3,
              onChanged: (bool value) async {
                await HapticService().triggerHaptic(
                  HapticType.SELECTION,
                  context,
                );

                setBool("material3", value);
                updateData();
                material3Notifier.value = value;
              },
            ),
          ),
          ListTile(
            title: Text("Dynamic theme"),
            subtitle: Text(
              "Use Android's dynamic theme system. Supported on Material You (Android 12+.).",
            ),
            enabled: _dynamicSupported && _material3,
            trailing: (_dynamicSupported && _material3
                ? Switch(
                    value: _dynamicTheme,
                    onChanged: (bool value) async {
                      await HapticService().triggerHaptic(
                        HapticType.SELECTION,
                        context,
                      );

                      setBool("dynamicTheme", value);
                      updateData();
                      dynamicThemeNotifier.value = value;
                    },
                  )
                : const SizedBox.shrink()),
          ),
          ListTile(
            title: Text("Theme color"),
            subtitle: Text(
              "Choose a custom theme color if you are not using Android's dynamic theme feature.",
            ),
            enabled: (!_dynamicTheme || !_dynamicSupported),
          ),
          if (!_dynamicTheme || !_dynamicSupported)
            colorSelector(context, _themeColor, (newColor) {
              setInt("themeColor", newColor);
              updateData();
              themeColorNotifier.value = newColor;
            }),
          Divider(
            height: 0,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          ListTile(
            title: Text("Log events"),
            subtitle: Text(
              "Log various events such as changes between mobile cells and technologies.",
            ),
            trailing: Switch(
              value: _logEvents,
              onChanged: (bool value) async {
                await HapticService().triggerHaptic(
                  HapticType.SELECTION,
                  context,
                );

                setBool("logEvents", value);
                updateData();
                logsNotifier.value = value;
              },
            ),
          ),
          if (_logEvents)
            eventSelection(context, _loggedEventTypes, (eventType) {
              if (_loggedEventTypes.contains(eventType)) {
                _loggedEventTypes.remove(eventType);
              } else {
                _loggedEventTypes.add(eventType);
              }

              setStringList(
                "loggedEventTypes",
                _loggedEventTypes.map((e) => e.name).toList(),
              );

              updateData();
            }),
          ListTile(
            title: Text("Maximum logs ($_maximumLogs)"),
            subtitle: Text(
              "The maximum amount of events that should be logged and stored.",
            ),
            enabled: _logEvents,
          ),
          if (_logEvents)
            Slider(
              value: _maximumLogs.toDouble(),
              max: 500,
              min: 10,
              label: _maximumLogs.toString(),
              onChanged: (double value) {
                setInt("maximumLogs", value.toInt());
                updateData();
              },
            ),
          Divider(
            height: 0,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          ListTile(
            title: Text("Metric system"),
            subtitle: Text(
              "Use the metric system for speed measurements in the map.",
            ),
            trailing: Switch(
              value: _metricSystem,
              onChanged: (bool value) async {
                await HapticService().triggerHaptic(
                  HapticType.SELECTION,
                  context,
                );

                setBool("metricSystem", value);
                metricSystemNotifier.value = value;
                updateData();
              },
            ),
          ),
          ListTile(
            title: Text("Map tiles template URL"),
            subtitle: Text("The custom map tiles template URL."),
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              bottom: 12.0,
            ),
            child: TextField(
              autocorrect: false,
              controller: _mapTilesTemplateController,
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r"https?:\/\/[\w\.\/\-?#%&={}\[\]+]+"),
                ),
              ],
              decoration: const InputDecoration(border: UnderlineInputBorder()),
              onChanged: (String value) async {
                await HapticService().triggerHaptic(
                  HapticType.SELECTION,
                  context,
                );

                setString("mapTilesTemplate", value);
                _mapTilesTemplate = value;
                mapTilesTemplateNotifier.value = value;
              },
            ),
          ),
          Divider(
            height: 0,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          ListTile(
            title: Text("Speed measurement unit"),
            subtitle: Text(
              "Choose your preferred speed measurement unit for speedtests.",
            ),
            trailing: IconButton(
              icon: Icon(Icons.edit),
              onPressed: () => showDialog(
                context: context,
                builder: (BuildContext context) {
                  return speedMeasurementUnitDialog(
                    context,
                    speedMeasurementUnits,
                    _speedMeasurementUnitSelection,
                    (index, value) {
                      setState(() {
                        _speedMeasurementUnitSelection = value;
                      });

                      setInt("speedMeasurementUnit", index);
                      speedMeasurementUnitNotifier.value = index;
                      updateData();
                    },
                  );
                },
              ),
            ),
          ),
          ListTile(
            title: Text("Speed test instance URL"),
            subtitle: Text(
              "Your speed test server instance URL. (Supported backends: LibreSpeed).",
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              bottom: 12.0,
            ),
            child: TextField(
              autocorrect: false,
              controller: _speedtestInstanceController,
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r"https?:\/\/[\w\.\/\-?#%&={}\[\]+]+"),
                ),
              ],
              decoration: const InputDecoration(border: UnderlineInputBorder()),
              onChanged: (String value) async {
                await HapticService().triggerHaptic(
                  HapticType.SELECTION,
                  context,
                );

                setString("speedtestInstance", value);
                _speedtestInstance = value;
                speedtestInstanceNotifier.value = value;
              },
            ),
          ),
          Divider(
            height: 0,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          ListTile(
            title: Text("External databases"),
            subtitle: Text(
              "Use external databases to show additional info about cell towers in the home screen.",
            ),
            trailing: Switch(
              value: _externalDatabases,
              onChanged: (bool value) async {
                await HapticService().triggerHaptic(
                  HapticType.SELECTION,
                  context,
                );

                setBool("externalDatabases", value);
                externalDatabasesNotifier.value = value;
                updateData();
              },
            ),
          ),
          ListTile(
            title: Text("Database cells in map"),
            subtitle: Text(
              "Show the cells imported from a database in the map.",
            ),
            enabled: _externalDatabases,
            trailing: _externalDatabases
                ? Switch(
                    value: _databaseCellsInMap,
                    onChanged: (bool value) async {
                      await HapticService().triggerHaptic(
                        HapticType.SELECTION,
                        context,
                      );

                      setBool("databaseCellsInMap", value);
                      databaseCellsInMapNotifier.value = value;
                      updateData();
                    },
                  )
                : const SizedBox.shrink(),
          ),
          ListTile(
            title: Text("Import database"),
            subtitle: Text(
              "Import external databases for various mobile networks. You have imported ${_importedDatabases.length} databases so far.",
            ),
            enabled: _externalDatabases,
            trailing: IconButton(
              icon: Icon(Icons.download_outlined),
              onPressed: () => showDialog(
                context: context,
                builder: (BuildContext context) {
                  return DatabaseManagerDialog(
                    sharedPreferences: sharedPreferences,
                    importedDatabases: _importedDatabases,
                    onUpdate: updateData,
                  );
                },
              ),
            ),
          ),
          Divider(
            height: 0,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          ListTile(
            title: Text("Contribute"),
            subtitle: Text("Contribute to NetManager on GitHub."),
            trailing: IconButton(
              onPressed: () {
                Uri url = Uri.parse('https://github.com/DottoXD/NetManager');
                launchUrl(url);
              },
              icon: Icon(Icons.open_in_new),
              tooltip: "Open in a browser",
            ),
          ),
          ListTile(
            title: Text("Telegram"),
            subtitle: Text(
              "Join NetManager's Telegram for exclusive feature previews and showcases.",
            ),
            trailing: IconButton(
              onPressed: () {
                Uri url = Uri.parse('https://t.me/netmanagerapp');
                launchUrl(url);
              },
              icon: Icon(Icons.message_outlined),
              tooltip: "Open in a browser",
            ),
          ),
          ListTile(
            title: Text("About"),
            subtitle: Text(
              "View some info about NetManager. Open source licenses and credits are included in this page.",
            ),
            trailing: IconButton(
              onPressed: () => showDialog(
                context: context,
                builder: (BuildContext context) =>
                    FullAboutDialog(platform: platform),
              ),
              icon: Icon(Icons.question_mark_outlined),
            ),
          ),
          Divider(
            height: 0,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          ListTile(
            title: Text("Use new backend (BETA)"),
            subtitle: Text(
              "Use the brand new, BETA data collection & calculation core. The brand new NetManager Core engine is lighter and faster, but you may encounter slight issues with it. Note that toggling this setting will close the app.",
            ),
            trailing: Switch(
              value: _useNewCore,
              onChanged: (bool value) async {
                await HapticService().triggerHaptic(
                  HapticType.SELECTION,
                  context,
                );

                setBool("useNewCore", value);
                await updateData();

                await platform.invokeMethod<void>("cancelNotification");
                await platform.invokeMethod<void>("stopRecording");
                exit(0);
              },
            ),
          ),
          ListTile(
            title: Text("Debug"),
            subtitle: Text(
              "Manage NetManager's debug mode. Enabling this setting will show raw debug data in some parts of the app.",
            ),
            trailing: Switch(
              value: _debug,
              onChanged: (bool value) async {
                await HapticService().triggerHaptic(
                  HapticType.SELECTION,
                  context,
                );

                setBool("debug", value);
                updateData();
                debugNotifier.value = value;
              },
            ),
          ),
          if (_debug)
            ListTile(
              title: Text("Debug Logs"),
              subtitle: Text(
                "View NetManager's debug logs. Useful for debugging issues or viewing additional info.",
              ),
              enabled: _debug,
              trailing: IconButton(
                onPressed: openDebugLogs,
                icon: Icon(Icons.pageview_outlined),
                tooltip: "View",
              ),
            ),
        ],
      ),
    );
  }
}
