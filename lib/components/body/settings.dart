
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsBody extends StatefulWidget {
  const SettingsBody(this.platform, this.sharedPreferences, { super.key });
  final MethodChannel platform;
  final SharedPreferences sharedPreferences;

  @override
  State<SettingsBody> createState() => _SettingsBodyState();
}

class _SettingsBodyState extends State<SettingsBody> {
  late MethodChannel platform;
  late SharedPreferences sharedPreferences;

  final List<String> positionPrecisions = [
    "Off",
    "Low",
    "Medium",
    "High"
  ];

  bool _startupMonitoring = false;
  bool _backgroundService = false;
  bool _analytics = false;
  int _updateInterval = 3;
  int _backgroundUpdateInterval = 3;
  int _positionPrecision = 3;
  int _themeColor = 0xFF157F76;

  bool _dynamicSupported = true;
  bool _dynamicTheme = true;

  late String _selection;

  @override
  void initState() {
    super.initState();
    platform = widget.platform;
    sharedPreferences = widget.sharedPreferences;

    updateData();
    _selection = positionPrecisions[_positionPrecision];
  }

  void updateData() {
    setState(() {
      _startupMonitoring = sharedPreferences.getBool("startupMonitoring") ?? _startupMonitoring;
      _backgroundService = sharedPreferences.getBool("backgroundService") ?? _backgroundService;
      _analytics = sharedPreferences.getBool("analytics") ?? _analytics;
      _updateInterval = sharedPreferences.getInt("updateInterval") ?? _updateInterval;
      _backgroundUpdateInterval = sharedPreferences.getInt("backgroundUpdateInterval") ?? _backgroundUpdateInterval;
      _positionPrecision = sharedPreferences.getInt("positionPrecision") ?? _positionPrecision;
      _dynamicTheme = sharedPreferences.getBool("dynamicTheme") ?? _dynamicTheme;
      _themeColor = sharedPreferences.getInt("themeColor") ?? _themeColor;

      _dynamicSupported = sharedPreferences.getBool("dynamicSupported") ?? _dynamicSupported;
      _dynamicTheme = sharedPreferences.getBool("dynamicTheme") ?? _dynamicTheme;
    });
  }

  void setBool(String key, bool value) {
    sharedPreferences.setBool(key, value);
  }

  void setInt(String key, int value) {
    sharedPreferences.setInt(key, value);
  }

  Future<dynamic> _showDialog(BuildContext context) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Edit precision'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  ...positionPrecisions.asMap().entries.map((precision) {
                    return RadioListTile(
                      title: Text(precision.value),
                      value: precision.value,
                      groupValue: _selection,
                      onChanged: (value) {
                        if(value != null) {
                          setState(() {
                            _selection = value;
                          });

                          setInt("positionPrecision", precision.key);
                          updateData();
                        }
                      },
                    );
                  })
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Edit'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          children: <Widget>[
            Row(
                children: [
                  //Expanded(child: LinearProgressIndicator()),
                ]
            ),
            Row(
              children: [
                Expanded(
                    child: ListView(
                      shrinkWrap: true,
                      physics: ClampingScrollPhysics(),
                      children: <Widget>[
                        ListTile(
                          title: Text("Analytics"),
                          subtitle: Text("Share anonymous insights to help me improve NetManager."),
                          trailing: Switch(
                            value: _analytics,
                            onChanged: (bool value) {
                              setBool("analytics", value);
                              updateData();
                            },
                          ),
                        ),
                        Divider(
                          height: 0,
                        ),
                        ListTile(
                          title: Text("Position precision (${positionPrecisions[_positionPrecision]})"),
                          subtitle: Text("The precision of your position determines the precision of the map tracking service."),
                          trailing: IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {
                              _showDialog(context);
                            },
                          ),
                        ),
                        ListTile(
                          title: Text("Startup monitoring"),
                          subtitle: Text("Start the monitoring service with your device. The map tracking service still needs to be manually started in the app."),
                          trailing: Switch(
                            value: _startupMonitoring,
                            onChanged: (bool value) {
                              setBool("startupMonitoring", value);
                              updateData();
                            },
                          ),
                        ),
                        ListTile(
                          title: Text("Background service"),
                          subtitle: Text("Keep the monitoring service running even when you shut down the app."),
                          trailing: Switch(
                            value: _backgroundService,
                            onChanged: (bool value) {
                              setBool("backgroundService", value);
                              updateData();
                            },
                          ),
                        ),
                        ListTile(
                          title: Text("Update interval (${_updateInterval}s)"),
                          subtitle: Text("The interval in seconds between each monitoring service data update."),
                        ),
                        Slider(
                          value: _updateInterval.toDouble(),
                          max: 60,
                          min: 1,
                          label: _updateInterval.toString(),
                          onChanged: (double value) {
                            setInt("updateInterval", value.toInt());
                            updateData();
                          },
                        ),
                        ListTile(
                            title: Text("Background update interval (${_backgroundUpdateInterval}s)"),
                            subtitle: Text("The interval between each monitoring service data update when it is running in the background or on startup."),
                            enabled: (_backgroundService || _startupMonitoring)
                        ),
                        if(_backgroundService || _startupMonitoring) Slider(
                          value: _backgroundUpdateInterval.toDouble(),
                          max: 60,
                          min: 1,
                          label: _backgroundUpdateInterval.toString(),
                          onChanged: (double value) {
                            setInt("backgroundUpdateInterval", value.toInt());
                            updateData();
                          },
                        ),
                        Divider(
                          height: 0,
                        ),
                        ListTile(
                          title: Text("Dynamic theme"),
                          subtitle: Text("Use Android's dynamic theme system. Supported on Android 12+."),
                          enabled: _dynamicSupported,
                          trailing: Switch(
                            value: _dynamicTheme,
                            onChanged: (bool value) {
                              if(_dynamicSupported) {
                                setBool("dynamicTheme", value);
                                updateData();
                              }
                            },
                          ),
                        ),
                        ListTile(
                          title: Text("Theme color (not available)"),
                          subtitle: Text("Choose a custom theme color in case you are not using Android's dynamic theme feature."),
                          enabled: (!_dynamicTheme || !_dynamicSupported),
                        ),
                      ],
                    )
                )
              ],
            )
          ],
        )
    );
  }
}