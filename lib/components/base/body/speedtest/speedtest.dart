import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:netmanager/components/base/body/speedtest/widgets/hero_gauge.dart';
import 'package:netmanager/components/base/body/speedtest/widgets/quality_metrics.dart';
import 'package:netmanager/components/base/body/speedtest/widgets/speed_results.dart';
import 'package:netmanager/components/dialogs/error.dart';
import 'package:netmanager/components/modals/server_modal.dart';
import 'package:netmanager/types/speedtest/metrics.dart';
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

  final ValueNotifier<SpeedtestMetrics> _metricsNotifier = ValueNotifier(
    SpeedtestMetrics(),
  );
  final ValueNotifier<Map<String, dynamic>?> _selectedServerNotifier =
      ValueNotifier(null);

  late String _speedtestServer;
  List<dynamic> _servers = [];
  int _unitIndex = 1;
  int _fetchServersRetries = 0;

  @override
  void initState() {
    super.initState();
    platform = widget.platform;
    sharedPreferences = widget.sharedPreferences;

    _speedtestServer =
        sharedPreferences.getString("speedtestInstance") ??
        defaultSpeedtestServer;

    _unitIndex = widget.sharedPreferences.getInt("speedMeasurementUnit") ?? 1;

    if (_speedtestServer.endsWith("/")) {
      _speedtestServer = _speedtestServer.substring(
        0,
        _speedtestServer.length - 1,
      ); // risky? yes
    }

    _fetchServers();

    platform.setMethodCallHandler((call) async {
      final currentMetrics = _metricsNotifier.value;

      switch (call.method) {
        case "update":
          final String newStageStr = call.arguments["stage"];
          final double newSpeed = (call.arguments["speed"] as num).toDouble();
          final double newProgress =
              (call.arguments["progress"] as num?)?.toDouble() ?? 0.0;
          final double currentLoss =
              (call.arguments["packetLoss"] as num?)?.toDouble() ??
              currentMetrics.packetLoss;
          final TestStage nextStage = TestStage.values.byName(newStageStr);
          double nextScale = currentMetrics.maxSpeedScale;

          if (currentMetrics.stage == TestStage.DOWNLOAD &&
              nextStage == TestStage.UPLOAD) {
            nextScale = 100.0;
          }

          if (newSpeed > nextScale) {
            nextScale = switch (newSpeed) {
              > 2500 => 5000,
              > 1000 => 2500,
              > 300 => 1000,
              > 100 => 300,
              _ => 100,
            };
          }

          _metricsNotifier.value = currentMetrics.copyWith(
            currentSpeed: newSpeed,
            maxSpeedScale: nextScale,
            stage: nextStage,
            progress: newProgress,
            packetLoss: currentLoss,
          );
          break;

        case "latency":
          _metricsNotifier.value = currentMetrics.copyWith(
            ping: call.arguments["ping"],
            jitter: call.arguments["jitter"],
            packetLoss: (call.arguments["packetLoss"] as num).toDouble(),
            latencyProgress: (call.arguments["progress"] as num).toDouble(),
          );
          break;

        case "complete":
          _metricsNotifier.value = currentMetrics.copyWith(
            downloadResult: (call.arguments["download"] as num).toDouble(),
            uploadResult: (call.arguments["upload"] as num).toDouble(),
            stage: TestStage.FINISHED,
            currentSpeed: 0.0,
            progress: 0.0,
          );
          break;

        case "error":
          _metricsNotifier.value = currentMetrics.copyWith(
            stage: TestStage.IDLE,
            currentSpeed: 0.0,
            progress: 0.0,
            latencyProgress: 0.0,
          );
          if (mounted) {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return errorDialog(context, call.arguments);
              },
            );
          }
          break;
      }
    });
  }

  @override
  void dispose() {
    _selectedServerNotifier.dispose();
    _metricsNotifier.dispose();
    platform.setMethodCallHandler(null);
    super.dispose();
  }

  Future<void> _fetchServers() async {
    String primaryUrl = "$_speedtestServer/server-list.json";
    String fallbackUrl = "$_speedtestServer/backend-servers/servers.php";

    try {
      final response = await http
          .get(Uri.parse(primaryUrl))
          .timeout(Duration(milliseconds: 2000));

      if (response.statusCode == 200) {
        _updateServers(response.body);
      } else {
        throw Exception("");
      }
    } catch (e) {
      try {
        final response = await http
            .get(Uri.parse(fallbackUrl))
            .timeout(Duration(milliseconds: 2000));

        if (response.statusCode == 200) {
          _updateServers(response.body);
        } else {
          throw Exception("The speed test server is unreachable.");
        }
      } catch (e) {
        _fetchServersRetries++;

        Future.delayed(const Duration(milliseconds: 2000)).then((val) {
          if (mounted) {
            if (_fetchServersRetries >= 3) {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return errorDialog(context, e);
                },
              );
            } else {
              _fetchServers();
            }
          }
        });
      }
    }
  }

  void _updateServers(String body) async {
    try {
      final List<dynamic> data = json.decode(body);

      if (data.isNotEmpty) {
        setState(() {
          _servers = data;
          _selectedServerNotifier.value = _servers[0];
        });

        final List<Map<String, dynamic>> validResults = [];

        for (int i = 0; i < data.length; i += 5) {
          final int end = i + 5 > data.length ? data.length : i + 5;
          final List<dynamic> chunk = data.sublist(i, end);

          final List<Future<Map<String, dynamic>?>> chunkFutureServers = chunk
              .map((server) async {
                String serverUrl = server["server"] ?? "";
                if (serverUrl.isEmpty) return null;

                if (!serverUrl.endsWith('/')) serverUrl += '/';
                if (serverUrl.startsWith("//")) serverUrl = "https:$serverUrl";

                serverUrl += server["dlURL"];

                try {
                  final stopwatch = Stopwatch()..start();
                  final response = await http
                      .head(Uri.parse(serverUrl))
                      .timeout(Duration(milliseconds: 1000));

                  stopwatch.stop();

                  if (response.statusCode >= 200 && response.statusCode < 300) {
                    return {
                      "server": server,
                      "latency": stopwatch.elapsedMilliseconds,
                    };
                  }
                } catch (e) {}
              })
              .toList();

          final chunkResults = await Future.wait(chunkFutureServers);
          for (final result in chunkResults) {
            if (result != null) {
              validResults.add(result);
            }
          }
        }

        validResults.sort(
          (a, b) => (a["latency"] as int).compareTo(b["latency"] as int),
        );

        final List<dynamic> sortedServers = validResults
            .map((result) => result["server"])
            .toList();

        if (sortedServers.isEmpty) {
          _fetchServersRetries++;
          throw Error();
        } else {
          _fetchServersRetries = 0;
        }

        if (mounted) {
          setState(() {
            _servers = sortedServers;

            if (_servers.isNotEmpty) {
              _selectedServerNotifier.value = _servers[0];
            } else {
              _selectedServerNotifier.value = null;
            }
          });
        }
      }
    } catch (e) {
      Future.delayed(const Duration(seconds: 2)).then((val) {
        if (mounted) {
          _fetchServers();
        }
      });
    }
  }

  void _startTest() {
    if (_selectedServerNotifier.value == null) return;

    _metricsNotifier.value = SpeedtestMetrics(stage: TestStage.LATENCY);

    String baseUrl = _selectedServerNotifier.value!["server"];
    if (!baseUrl.endsWith('/')) baseUrl += '/';
    if (baseUrl.startsWith("//")) baseUrl = "https:$baseUrl";

    platform.invokeMethod("startTest", {
      "pingUrl": baseUrl + _selectedServerNotifier.value!["pingURL"],
      "downloadUrl": baseUrl + _selectedServerNotifier.value!["dlURL"],
      "uploadUrl": baseUrl + _selectedServerNotifier.value!["ulURL"],
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
                  valueListenable: _selectedServerNotifier,
                  builder: (context, selectedServer, child) {
                    return ValueListenableBuilder(
                      valueListenable: _metricsNotifier,
                      builder: (context, metrics, child) {
                        final bool isRunning =
                            metrics.stage != TestStage.IDLE &&
                            metrics.stage != TestStage.FINISHED;

                        String sponsorName = "";
                        if (selectedServer != null) {
                          sponsorName = selectedServer["sponsorName"];
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 32),
                          child: OutlinedButton.icon(
                            onPressed: isRunning
                                ? null
                                : () {
                                    showModalBottomSheet(
                                      context: context,
                                      showDragHandle: true,
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
                                          _selectedServerNotifier,
                                        );
                                      },
                                    );
                                  },
                            icon: const Icon(Icons.dns_outlined, size: 18),
                            label: Text(
                              selectedServer != null
                                  ? "$sponsorName (${(selectedServer["name"]).toString().replaceAll(" ($sponsorName)", "")})"
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
                    );
                  },
                ),
                ValueListenableBuilder(
                  valueListenable: _metricsNotifier,
                  builder: (context, metrics, child) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HeroGauge(
                          stage: metrics.stage,
                          latencyProgress: metrics.latencyProgress,
                          currentSpeed: metrics.currentSpeed,
                          maxSpeedScale: metrics.maxSpeedScale,
                          ping: metrics.ping,
                          downloadResult: metrics.downloadResult,
                          uploadResult: metrics.uploadResult,
                          unitIndex: _unitIndex,
                        ),
                        const SizedBox(height: 48),
                        QualityMetrics(
                          ping: metrics.ping,
                          jitter: metrics.jitter,
                          packetLoss: metrics.packetLoss,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        ValueListenableBuilder(
          valueListenable: _metricsNotifier,
          builder: (context, metrics, child) {
            return SpeedResults(
              stage: metrics.stage,
              downloadResult: metrics.downloadResult,
              uploadResult: metrics.uploadResult,
              progress: metrics.progress,
              startTest: _startTest,
              unitIndex: _unitIndex,
            );
          },
        ),
        if (isDefaultServer)
          Container(
            width: double.maxFinite,
            padding: const EdgeInsets.fromLTRB(12.0, 6.0, 12.0, 20.0),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
            ),
            child: Text(
              "Powered by LibreSpeed",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}
