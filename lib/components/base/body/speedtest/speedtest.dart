import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:netmanager/components/base/body/speedtest/widgets/hero_gauge.dart';
import 'package:netmanager/components/base/body/speedtest/widgets/quality_metrics.dart';
import 'package:netmanager/components/base/body/speedtest/widgets/speed_results.dart';
import 'package:netmanager/components/dialogs/error.dart';
import 'package:netmanager/components/modals/server_modal.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TestStage { IDLE, LATENCY, DOWNLOAD, UPLOAD, FINISHED }

class SpeedtestBody extends StatefulWidget {
  final MethodChannel platform;
  final SharedPreferences sharedPreferences;
  const SpeedtestBody(this.platform, this.sharedPreferences, {super.key});

  @override
  State<SpeedtestBody> createState() => _SpeedtestBodyState();
}

class _SpeedtestBodyState extends State<SpeedtestBody> {
  late MethodChannel platform;
  late SharedPreferences sharedPreferences;

  final String defaultSpeedtestServer = "https://librespeed.org";

  TestStage _stage = TestStage.IDLE;

  double _currentSpeed = 0.0;
  int _ping = 0;
  double _latencyProgress = 0.0;
  int _jitter = 0;
  double _packetLoss = 0.0;
  double _downloadResult = 0.0;
  double _uploadResult = 0.0;
  double _maxSpeedScale = 100.0;

  late ValueNotifier<Map<String, dynamic>?> selectedServerNotifier =
      ValueNotifier(null);

  late String _speedtestServer;
  List<dynamic> _servers = [];

  @override
  void initState() {
    super.initState();
    platform = widget.platform;
    sharedPreferences = widget.sharedPreferences;

    _speedtestServer =
        sharedPreferences.getString("speedtestInstance") ??
        defaultSpeedtestServer;

    if (_speedtestServer.endsWith("/")) {
      _speedtestServer = _speedtestServer.substring(
        0,
        _speedtestServer.length - 1,
      ); // risky? yes
    }

    _fetchServers();

    platform.setMethodCallHandler((call) async {
      switch (call.method) {
        case "update":
          final String newStageStr = call.arguments["stage"];
          final double newSpeed = (call.arguments["speed"] as num).toDouble();

          setState(() {
            if (_stage == TestStage.DOWNLOAD && newStageStr == "UPLOAD") {
              _maxSpeedScale = 100.0;
            }

            _stage = TestStage.values.byName(newStageStr);
            _currentSpeed = newSpeed;

            if (_currentSpeed > _maxSpeedScale) {
              _maxSpeedScale = switch (_currentSpeed) {
                > 2500 => 5000,
                > 1000 => 2500,
                > 300 => 1000,
                > 100 => 300,
                _ => 100,
              };
            }
          });
          break;

        case "latency":
          setState(() {
            _ping = call.arguments["ping"];
            _jitter = call.arguments["jitter"];
            _packetLoss = (call.arguments["packetLoss"] as num).toDouble();
            _latencyProgress = (call.arguments["progress"] as num).toDouble();
          });
          break;

        case "complete":
          setState(() {
            _downloadResult = (call.arguments["download"] as num).toDouble();
            _uploadResult = (call.arguments["upload"] as num).toDouble();
            _stage = TestStage.FINISHED;
            _currentSpeed = 0.0;
          });
          break;
      }
    });
  }

  @override
  void dispose() {
    selectedServerNotifier.dispose();
    super.dispose();
  }

  Future<void> _fetchServers() async {
    String primaryUrl = "$_speedtestServer/server-list.json";
    String fallbackUrl = "$_speedtestServer/backend-servers/servers.php";

    try {
      final response = await http.get(Uri.parse(primaryUrl));

      if (response.statusCode == 200) {
        _updateServers(response.body);
      } else {
        throw Exception("");
      }
    } catch (e) {
      try {
        final response = await http.get(Uri.parse(fallbackUrl));

        if (response.statusCode == 200) {
          _updateServers(response.body);
        } else {
          throw Exception("The speed test server is unreachable.");
        }
      } catch (e) {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return errorDialog(context, e);
            },
          );
        }
      }
    }
  }

  void _updateServers(String body) async {
    try {
      final List<dynamic> data = json.decode(body);
      if (data.isNotEmpty) {
        setState(() {
          _servers = data;
          selectedServerNotifier.value = _servers[0];
        });
      }
    } catch (e) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return errorDialog(context, e);
          },
        );
      }
    }
  }

  void _startTest() {
    if (selectedServerNotifier.value == null) return;

    setState(() {
      _stage = TestStage.LATENCY;
      _currentSpeed = 0.0;
      _maxSpeedScale = 100.0;
      _ping = 0;
      _jitter = 0;
    });

    String baseUrl = selectedServerNotifier.value!["server"];
    if (!baseUrl.endsWith('/')) baseUrl += '/';
    if (baseUrl.startsWith("//")) baseUrl = "https:$baseUrl";

    platform.invokeMethod("startTest", {
      "pingUrl": baseUrl + selectedServerNotifier.value!["pingURL"],
      "downloadUrl": baseUrl + selectedServerNotifier.value!["dlURL"],
      "uploadUrl": baseUrl + selectedServerNotifier.value!["ulURL"],
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDefaultServer = _speedtestServer == defaultSpeedtestServer;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 24),
                ValueListenableBuilder(
                  valueListenable: selectedServerNotifier,
                  builder: (context, selectedServer, child) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 32),
                      child: OutlinedButton.icon(
                        onPressed:
                            _stage != TestStage.IDLE &&
                                _stage != TestStage.FINISHED
                            ? null
                            : () {
                                showModalBottomSheet(
                                  context: context,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(24.0),
                                    ),
                                  ),
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.surface,
                                  builder: (BuildContext context) {
                                    return serverModal(
                                      context,
                                      _servers,
                                      selectedServerNotifier,
                                    );
                                  },
                                );
                              },
                        icon: const Icon(Icons.dns_outlined, size: 18),
                        label: Text(
                          selectedServer != null
                              ? "${selectedServer["sponsorName"]} (${selectedServer["name"]})"
                              : "No server",
                        ),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                heroGauge(
                  context,
                  _stage,
                  _latencyProgress,
                  _currentSpeed,
                  _maxSpeedScale,
                  _ping,
                  _downloadResult,
                  _uploadResult,
                ),
                const SizedBox(height: 48),
                qualityMetrics(context, _ping, _jitter, _packetLoss),
              ],
            ),
          ),
        ),
        speedResults(
          context,
          _stage,
          _downloadResult,
          _uploadResult,
          _startTest,
        ),
        if (isDefaultServer)
          Container(
            width: double.maxFinite,
            padding: const EdgeInsets.all(12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
            ),
            child: Text(
              "Powered by LibreSpeed",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.4),
                fontSize: 11,
              ),
            ),
          ),
      ],
    );
  }
}
