import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:netmanager/components/base/body/speedtest/widgets/hero_gauge.dart';
import 'package:netmanager/components/base/body/speedtest/widgets/quality_metrics.dart';
import 'package:netmanager/components/base/body/speedtest/widgets/speed_results.dart';
import 'package:netmanager/components/dialogs/error.dart';
import 'package:netmanager/components/modals/server_modal.dart';
import 'package:netmanager/l10n/app_localizations.dart';
import 'package:netmanager/types/speedtest/metrics.dart';
import 'package:netmanager/utils/haptic_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TestStage { IDLE, LATENCY, DOWNLOAD, UPLOAD, FINISHED }

class SpeedtestBody extends StatefulWidget {
  final MethodChannel platform;
  final SharedPreferences sharedPreferences;

  final ValueNotifier<int> speedMeasurementUnitNotifier;
  final ValueNotifier<String> speedtestInstanceUrlNotifier;

  const SpeedtestBody(
    this.platform,
    this.sharedPreferences,
    this.speedMeasurementUnitNotifier,
    this.speedtestInstanceUrlNotifier, {
    super.key,
  });

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
  final ValueNotifier<bool> _serversLoadingNotifier = ValueNotifier(false);
  late AppLocalizations _appLocalizations;

  List<dynamic> _servers = [];
  int _fetchServersRetries = 0;
  bool _dialogOpen = false;

  String _getSpeedtestServer() {
    String url = widget.speedtestInstanceUrlNotifier.value.trim().isEmpty
        ? defaultSpeedtestServer
        : widget.speedtestInstanceUrlNotifier.value.trim();

    if (url.endsWith("/")) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  @override
  void initState() {
    super.initState();
    _appLocalizations = AppLocalizations.of(context)!;
    platform = widget.platform;
    sharedPreferences = widget.sharedPreferences;

    widget.speedtestInstanceUrlNotifier.addListener(_onServerUrlChanged);

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
          if (!_dialogOpen && mounted) {
            _dialogOpen = true;
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return errorDialog(
                  context,
                  "${_appLocalizations.speedtest}: ${call.arguments}",
                );
              },
            ).then((_) => _dialogOpen = false);
          }
          break;
      }
    });
  }

  @override
  void dispose() {
    _selectedServerNotifier.dispose();
    _metricsNotifier.dispose();
    _serversLoadingNotifier.dispose();
    platform.setMethodCallHandler(null);
    widget.speedtestInstanceUrlNotifier.removeListener(_onServerUrlChanged);
    super.dispose();
  }

  void _onServerUrlChanged() {
    _fetchServersRetries = 0;
    _fetchServers();
  }

  Future<void> _fetchServers() async {
    _serversLoadingNotifier.value = true;
    String primaryUrl = "${_getSpeedtestServer()}/server-list.json";
    String fallbackUrl = "${_getSpeedtestServer()}/backend-servers/servers.php";

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
          throw Exception(_appLocalizations.speedtestServerUnreachable);
        }
      } catch (e) {
        _fetchServersRetries++;

        Future.delayed(const Duration(milliseconds: 2000)).then((val) {
          if (mounted) {
            if (_fetchServersRetries >= 3) {
              if (!_dialogOpen) {
                _dialogOpen = true;
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return errorDialog(
                      context,
                      "${_appLocalizations.speedtest}: ${_appLocalizations.speedtestServerUnreachable}",
                    );
                  },
                ).then((_) => _dialogOpen = false);
              }
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
          throw Exception(_appLocalizations.noSpeedtestServers);
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

            _serversLoadingNotifier.value = false;
          });
        }
      }
    } catch (e) {
      _serversLoadingNotifier.value = false;
      Future.delayed(const Duration(seconds: 2)).then((val) {
        if (mounted) {
          if (_fetchServersRetries >= 3) {
            if (!_dialogOpen) {
              _dialogOpen = true;
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return errorDialog(
                    context,
                    _appLocalizations.speedtestServerUnreachable,
                  );
                },
              ).then((_) => _dialogOpen = false);
            }
          } else {
            _fetchServers();
          }
        }
      });
    }
  }

  void _startTest() {
    final server = _selectedServerNotifier.value;
    if (server == null) return;

    _metricsNotifier.value = SpeedtestMetrics(stage: TestStage.LATENCY);

    String baseUrl = server["server"];
    if (!baseUrl.endsWith('/')) baseUrl += '/';
    if (baseUrl.startsWith("//")) baseUrl = "https:$baseUrl";

    platform.invokeMethod("startTest", {
      "pingUrl": baseUrl + server["pingURL"],
      "downloadUrl": baseUrl + server["dlURL"],
      "uploadUrl": baseUrl + server["ulURL"],
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableHeight = constraints.maxHeight;
        final bool isCompact = availableHeight < 600;
        final bool isTiny = availableHeight < 500;

        final double gaugeSize = isTiny ? 200 : (isCompact ? 240 : 280);
        final double gaugeSpacer = isTiny ? 16 : (isCompact ? 28 : 48);
        final double serverSelectorPadding = isCompact ? 12 : 32;

        return Column(
          children: [
            ValueListenableBuilder(
              valueListenable: _serversLoadingNotifier,
              builder: (context, isLoading, child) {
                return isLoading
                    ? const LinearProgressIndicator()
                    : const SizedBox(height: 4);
              },
            ),
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
                              padding: EdgeInsets.only(
                                bottom: serverSelectorPadding,
                              ),
                              child: OutlinedButton.icon(
                                onPressed: isRunning
                                    ? null
                                    : () async {
                                        await HapticService().triggerHaptic(
                                          HapticType.selection,
                                          context,
                                        );

                                        if (context.mounted) {
                                          showModalBottomSheet(
                                            context: context,
                                            showDragHandle: true,
                                            shape: const RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.vertical(
                                                    top: Radius.circular(24.0),
                                                  ),
                                            ),
                                            backgroundColor: Theme.of(
                                              context,
                                            ).colorScheme.surface,
                                            builder: (BuildContext context) {
                                              return ServerModal(
                                                servers: _servers,
                                                selectedServerNotifier:
                                                    _selectedServerNotifier,
                                              );
                                            },
                                          );
                                        }
                                      },
                                icon: const Icon(Icons.dns_outlined, size: 18),
                                label: Text(
                                  selectedServer != null
                                      ? "$sponsorName (${(selectedServer["name"]).toString().replaceAll(" ($sponsorName)", "")})"
                                      : _appLocalizations.noSpeedtestServer,
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
                      valueListenable: widget.speedMeasurementUnitNotifier,
                      builder: (context, unitIndex, child) {
                        return ValueListenableBuilder(
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
                                  unitIndex: unitIndex,
                                  size: gaugeSize,
                                ),
                                SizedBox(height: gaugeSpacer),
                                if (!isTiny)
                                  QualityMetrics(
                                    ping: metrics.ping,
                                    jitter: metrics.jitter,
                                    packetLoss: metrics.packetLoss,
                                  ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            ValueListenableBuilder(
              valueListenable: widget.speedMeasurementUnitNotifier,
              builder: (context, unitIndex, child) {
                return ValueListenableBuilder(
                  valueListenable: _metricsNotifier,
                  builder: (context, metrics, child) {
                    return SpeedResults(
                      stage: metrics.stage,
                      downloadResult: metrics.downloadResult,
                      uploadResult: metrics.uploadResult,
                      progress: metrics.progress,
                      startTest: _startTest,
                      unitIndex: unitIndex,
                      isCompact: isCompact,
                    );
                  },
                );
              },
            ),
            ValueListenableBuilder(
              valueListenable: widget.speedtestInstanceUrlNotifier,
              builder: (context, urlValue, child) {
                final bool isDefaultServer =
                    urlValue.trim().isEmpty ||
                    urlValue.trim() == defaultSpeedtestServer;

                if (!isDefaultServer) return const SizedBox.shrink();

                return Container(
                  width: double.maxFinite,
                  padding: EdgeInsets.fromLTRB(
                    12.0,
                    isCompact ? 2.0 : 4.0,
                    12.0,
                    isCompact ? 8.0 : 20.0,
                  ),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                  ),
                  child: Text(
                    _appLocalizations.speedtestLibrespeed,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
