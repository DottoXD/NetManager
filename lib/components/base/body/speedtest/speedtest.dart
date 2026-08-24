import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:netmanager/components/base/body/speedtest/widgets/hero_gauge.dart';
import 'package:netmanager/components/base/body/speedtest/widgets/quality_metrics.dart';
import 'package:netmanager/components/base/body/speedtest/widgets/speed_results.dart';
import 'package:netmanager/components/dialogs/error.dart';
import 'package:netmanager/components/modals/server_modal.dart';
import 'package:netmanager/components/modals/speedtest_history_modal.dart';
import 'package:netmanager/database/speedtest_database.dart';
import 'package:netmanager/l10n/app_localizations.dart';
import 'package:netmanager/types/device/data.dart';
import 'package:netmanager/types/speedtest/history_result.dart';
import 'package:netmanager/types/speedtest/metrics.dart';
import 'package:netmanager/utils/haptic_service.dart';
import 'package:netmanager/utils/share_speedtest.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TestStage { IDLE, LATENCY, DOWNLOAD, UPLOAD, FINISHED }

class SpeedtestBody extends StatefulWidget {
  final MethodChannel platform;
  final SharedPreferences sharedPreferences;

  final ValueNotifier<int> speedMeasurementUnitNotifier;
  final ValueNotifier<int> speedtestBackendNotifier;
  final ValueNotifier<String> speedtestInstanceUrlNotifier;
  final ValueNotifier<bool> testRunningNotifier;
  final ValueNotifier<bool> canShareResultNotifier;

  final void Function(VoidCallback) onHistoryButtonPressed;
  final void Function(VoidCallback) onShareResultButtonPressed;

  const SpeedtestBody(
    this.platform,
    this.sharedPreferences,
    this.speedMeasurementUnitNotifier,
    this.speedtestBackendNotifier,
    this.speedtestInstanceUrlNotifier,
    this.testRunningNotifier,
    this.canShareResultNotifier, {
    required this.onHistoryButtonPressed,
    required this.onShareResultButtonPressed,
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
  final ValueNotifier<SpeedtestHistoryResult?> _lastResultNotifier =
      ValueNotifier(null);
  late AppLocalizations _appLocalizations;

  List<dynamic> _servers = [];
  int _fetchServersRetries = 0;
  bool _dialogOpen = false;
  Timer? _serverUrlDebounce;

  String _getSpeedtestServer() {
    String url = widget.speedtestInstanceUrlNotifier.value.trim();

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
    widget.speedtestBackendNotifier.addListener(_onServerUrlChanged);

    widget.onHistoryButtonPressed(_openHistoryModal);
    widget.onShareResultButtonPressed(_shareResult);

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
          final double downloadResult = (call.arguments["download"] as num)
              .toDouble();
          final double uploadResult = (call.arguments["upload"] as num)
              .toDouble();

          _metricsNotifier.value = currentMetrics.copyWith(
            downloadResult: downloadResult,
            uploadResult: uploadResult,
            stage: TestStage.FINISHED,
            currentSpeed: 0.0,
            progress: 0.0,
          );

          widget.testRunningNotifier.value = false;

          _saveHistoryResult(downloadResult, uploadResult, currentMetrics);
          break;

        case "error":
          _metricsNotifier.value = currentMetrics.copyWith(
            stage: TestStage.IDLE,
            currentSpeed: 0.0,
            progress: 0.0,
            latencyProgress: 0.0,
          );

          widget.testRunningNotifier.value = false;
          widget.canShareResultNotifier.value = false;

          _showErrorDialog("${_appLocalizations.speedtest}: ${call.arguments}");
          break;
      }
    });
  }

  @override
  void dispose() {
    _selectedServerNotifier.dispose();
    _metricsNotifier.dispose();
    _serversLoadingNotifier.dispose();
    _lastResultNotifier.dispose();
    _serverUrlDebounce?.cancel();
    platform.setMethodCallHandler(null);
    widget.speedtestInstanceUrlNotifier.removeListener(_onServerUrlChanged);
    widget.speedtestBackendNotifier.removeListener(_onServerUrlChanged);
    super.dispose();
  }

  void _onServerUrlChanged() {
    _serverUrlDebounce?.cancel();
    _serverUrlDebounce = Timer(const Duration(milliseconds: 1000), () {
      _fetchServersRetries = 0;
      _fetchServers();
    });
  }

  void _showErrorDialog(String message) {
    if (!_dialogOpen && mounted) {
      _dialogOpen = true;

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return ErrorDialog(e: message);
          },
        ).then((_) => _dialogOpen = false);
      }
    }
  }

  Future<void> _saveHistoryResult(
    double download,
    double upload,
    SpeedtestMetrics latencyMetrics,
  ) async {
    try {
      final String carrier =
          (await platform.invokeMethod<String>("getCarrier")) ?? "Unknown";
      final String plmn =
          (await platform.invokeMethod<String>("getPlmn")) ?? "00000";
      final int networkGen =
          await platform.invokeMethod<int>("getNetworkGen") ?? 0;

      String? serverName;
      final server = _selectedServerNotifier.value;
      final backend = widget.speedtestBackendNotifier.value;

      if (server != null) {
        if (backend == 1) {
          final sponsorName = server["sponsorName"];
          serverName = sponsorName != null
              ? "$sponsorName (${(server["name"]).toString().replaceAll(" ($sponsorName)", "")})"
              : server["name"]?.toString();
        } else {
          serverName = server["name"]?.toString();
        }
      }

      double? latitude;
      double? longitude;
      try {
        final String? rawLocation = await platform.invokeMethod<String>(
          "getLocation",
        );

        if (rawLocation != null) {
          final List<dynamic> coords = json.decode(rawLocation);
          if (coords.length == 2) {
            final double lat = (coords[0] as num).toDouble();
            final double lng = (coords[1] as num).toDouble();

            if (!(lat == 0.0 && lng == 0.0)) {
              latitude = lat;
              longitude = lng;
            }
          }
        }
      } on PlatformException catch (e) {
        await Sentry.captureException(e, stackTrace: e.stacktrace);
      }

      String? deviceModel;
      String? rawDeviceData = sharedPreferences.getString("deviceData");
      if (rawDeviceData != null) {
        final device = json.decode(rawDeviceData);
        if (device is Map<String, dynamic>) {
          try {
            final deviceData = DeviceData.fromJson(device);
            deviceModel = deviceData.model;
          } catch (e) {}
        }
      }

      final SpeedtestHistoryResult historyResult = SpeedtestHistoryResult(
        timestamp: DateTime.now(),
        download: download,
        upload: upload,
        ping: latencyMetrics.ping,
        jitter: latencyMetrics.jitter,
        packetLoss: latencyMetrics.packetLoss,
        carrier: carrier,
        plmn: plmn,
        networkGen: networkGen > 0 ? networkGen : 0,
        serverName: serverName,
        latitude: latitude,
        longitude: longitude,
        deviceModel: deviceModel,
      );

      await SpeedtestDatabase.insertResult(historyResult);

      _lastResultNotifier.value = historyResult;
      widget.canShareResultNotifier.value = true;
    } on PlatformException catch (e) {
      await Sentry.captureException(e, stackTrace: e.stacktrace);
    }
  }

  void _shareResult() async {
    final SpeedtestHistoryResult? result = _lastResultNotifier.value;
    if (result == null) return;

    await shareSpeedtestResult(
      context: context,
      platform: platform,
      result: result,
      unitIndex: widget.speedMeasurementUnitNotifier.value,
    );
  }

  void _openHistoryModal() async {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (BuildContext context) {
        return SpeedtestHistoryModal(
          platform: platform,
          speedMeasurementUnitNotifier: widget.speedMeasurementUnitNotifier,
        );
      },
    );
  }

  Future<void> _fetchServers() async {
    final int backend = widget.speedtestBackendNotifier.value;
    final String instanceUrl = widget.speedtestInstanceUrlNotifier.value.trim();

    if (backend == 0) {
      if (instanceUrl.isEmpty) {
        _serversLoadingNotifier.value = false;

        setState(() {
          _servers = [];
          _selectedServerNotifier.value = null;
        });

        _showErrorDialog(_appLocalizations.speedtestNoServerConfigured);

        return;
      }

      final parts = instanceUrl.split(";");
      final String dlUrl = parts[0].trim();
      final String ulUrl = parts.length > 1 ? parts[1].trim() : "";

      if (dlUrl.isEmpty || ulUrl.isEmpty) {
        _serversLoadingNotifier.value = false;

        setState(() {
          _servers = [];
          _selectedServerNotifier.value = null;
        });

        _showErrorDialog(_appLocalizations.speedtestNoServerConfigured);

        return;
      }

      final Uri? uri = Uri.tryParse(dlUrl);
      final String domain = (uri != null && uri.host.isNotEmpty)
          ? uri.host
          : dlUrl;

      final customServer = {
        "name": domain,
        "server": "",
        "pingURL": dlUrl,
        "dlURL": dlUrl,
        "ulURL": ulUrl,
        "isCustom": true,
      };

      if (mounted) {
        setState(() {
          _servers = [customServer];
          _selectedServerNotifier.value = customServer;
          _serversLoadingNotifier.value = false;
        });
      }

      return;
    }

    if (backend == 2) {
      String baseUrl = _getSpeedtestServer();
      if (baseUrl.isEmpty) {
        _serversLoadingNotifier.value = false;

        setState(() {
          _servers = [];
          _selectedServerNotifier.value = null;
        });

        _showErrorDialog(_appLocalizations.speedtestNoServerConfigured);

        return;
      }

      if (!baseUrl.startsWith("http://")) {
        baseUrl = "https://$baseUrl";
      }

      final ostServer = {
        "name": "OpenSpeedTest",
        "server": baseUrl,
        "pingURL": "/empty",
        "dlURL": "/downloading",
        "ulURL": "/upload",
        "isOpenSpeedTest": true,
      };

      if (mounted) {
        setState(() {
          _servers = [ostServer];
          _selectedServerNotifier.value = ostServer;
          _serversLoadingNotifier.value = false;
        });
      }

      return;
    }

    if (_getSpeedtestServer().isEmpty) {
      _serversLoadingNotifier.value = false;

      setState(() {
        _servers = [];
        _selectedServerNotifier.value = null;
      });

      _showErrorDialog(_appLocalizations.speedtestNoServerConfigured);
      return;
    }

    _serversLoadingNotifier.value = true;
    String primaryUrl = "${_getSpeedtestServer()}/server-list.json";
    String fallbackUrl = "${_getSpeedtestServer()}/backend-servers/servers.php";

    try {
      final response = await http
          .get(Uri.parse(primaryUrl))
          .timeout(const Duration(milliseconds: 2000));

      if (response.statusCode == 200) {
        _updateServers(response.body);
      } else {
        throw Exception("");
      }
    } catch (e) {
      try {
        final response = await http
            .get(Uri.parse(fallbackUrl))
            .timeout(const Duration(milliseconds: 2000));

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
              _showErrorDialog(
                "${_appLocalizations.speedtest}: ${_appLocalizations.speedtestServerUnreachable}",
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
        if (!widget.testRunningNotifier.value) {
          setState(() {
            _servers = data;
            _selectedServerNotifier.value = _servers[0];
          });
        }

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
                      .timeout(const Duration(milliseconds: 1000));

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

            if (!widget.testRunningNotifier.value) {
              if (_servers.isNotEmpty) {
                _selectedServerNotifier.value = _servers[0];
              } else {
                _selectedServerNotifier.value = null;
              }
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
            _showErrorDialog(_appLocalizations.speedtestServerUnreachable);
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
    widget.testRunningNotifier.value = true;
    widget.canShareResultNotifier.value = false;
    _lastResultNotifier.value = null;

    if (server["isCustom"] == true) {
      platform.invokeMethod("startTest", {
        "pingUrl": server["pingURL"],
        "downloadUrl": server["dlURL"],
        "uploadUrl": server["ulURL"],
      });

      return;
    }

    String baseUrl = server["server"] ?? "";
    if (!baseUrl.endsWith("/")) baseUrl += "/";
    if (baseUrl.startsWith("//")) baseUrl = "https:$baseUrl";

    String pingUrl = server["pingURL"] ?? "";
    String dlUrl = server["dlURL"] ?? "";
    String ulUrl = server["ulURL"] ?? "";

    String resolveUrl(String path) {
      if (path.startsWith("//")) path = "https:$path";
      if (path.startsWith("http://") || path.startsWith("https://")) {
        return path;
      }
      if (path.startsWith("/")) path = path.substring(1);

      return baseUrl + path;
    }

    platform.invokeMethod("startTest", {
      "pingUrl": resolveUrl(pingUrl),
      "downloadUrl": resolveUrl(dlUrl),
      "uploadUrl": resolveUrl(ulUrl),
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
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
              child: LayoutBuilder(
                builder: (context, innerConstraints) {
                  final double availableHeight = innerConstraints.maxHeight;
                  final bool isCompact = availableHeight < 500;
                  final bool isTiny = availableHeight < 400;

                  final double gaugeSize = (availableHeight * 0.425).clamp(
                    220.0,
                    320.0,
                  );
                  final double gaugeSpacer = (availableHeight * 0.07).clamp(
                    16.0,
                    56.0,
                  );
                  final double serverSelectorPadding = isCompact ? 8 : 16;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        SizedBox(height: isCompact ? 8 : 16),
                        ValueListenableBuilder(
                          valueListenable: widget.speedtestBackendNotifier,
                          builder: (context, backend, child) {
                            return ValueListenableBuilder(
                              valueListenable: _selectedServerNotifier,
                              builder: (context, selectedServer, child) {
                                return ValueListenableBuilder(
                                  valueListenable: _metricsNotifier,
                                  builder: (context, metrics, child) {
                                    final bool isRunning =
                                        metrics.stage != TestStage.IDLE &&
                                        metrics.stage != TestStage.FINISHED;

                                    String buttonLabel;
                                    bool canSelectServer = false;

                                    if (backend == 1) {
                                      canSelectServer =
                                          !isRunning && _servers.length > 1;
                                      if (selectedServer != null) {
                                        final sponsorName =
                                            selectedServer["sponsorName"];
                                        buttonLabel = sponsorName != null
                                            ? "$sponsorName (${(selectedServer["name"]).toString().replaceAll(" ($sponsorName)", "")})"
                                            : selectedServer["name"]
                                                      ?.toString() ??
                                                  _appLocalizations
                                                      .noSpeedtestServer;
                                      } else {
                                        buttonLabel =
                                            _appLocalizations.noSpeedtestServer;
                                      }
                                    } else if (backend == 2) {
                                      buttonLabel = "OpenSpeedTest";
                                    } else {
                                      buttonLabel = selectedServer != null
                                          ? selectedServer["name"].toString()
                                          : _appLocalizations.noSpeedtestServer;
                                    }

                                    return Padding(
                                      padding: EdgeInsets.only(
                                        bottom: serverSelectorPadding,
                                      ),
                                      child: OutlinedButton.icon(
                                        onPressed: canSelectServer
                                            ? () async {
                                                await HapticService()
                                                    .triggerHaptic(
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
                                                            top:
                                                                Radius.circular(
                                                                  24.0,
                                                                ),
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
                                              }
                                            : null,
                                        icon: const Icon(
                                          Icons.dns_outlined,
                                          size: 18,
                                        ),
                                        label: Text(buttonLabel),
                                        style: OutlinedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                        Expanded(
                          child: Center(
                            child: ValueListenableBuilder(
                              valueListenable:
                                  widget.speedMeasurementUnitNotifier,
                              builder: (context, unitIndex, child) {
                                return ValueListenableBuilder(
                                  valueListenable: _metricsNotifier,
                                  builder: (context, metrics, child) {
                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        HeroGauge(
                                          stage: metrics.stage,
                                          latencyProgress:
                                              metrics.latencyProgress,
                                          currentSpeed: metrics.currentSpeed,
                                          maxSpeedScale: metrics.maxSpeedScale,
                                          ping: metrics.ping,
                                          downloadResult:
                                              metrics.downloadResult,
                                          uploadResult: metrics.uploadResult,
                                          unitIndex: unitIndex,
                                          size: gaugeSize,
                                        ),
                                        if (!isTiny) ...[
                                          SizedBox(height: gaugeSpacer),
                                          QualityMetrics(
                                            ping: metrics.ping,
                                            jitter: metrics.jitter,
                                            packetLoss: metrics.packetLoss,
                                          ),
                                        ],
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
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
                      isCompact: constraints.maxHeight < 480,
                    );
                  },
                );
              },
            ),
            ValueListenableBuilder(
              valueListenable: widget.speedtestBackendNotifier,
              builder: (context, backend, child) {
                if (backend == 0) {
                  return const SizedBox.shrink();
                }

                String bannerText = "";
                if (backend == 1) {
                  final String urlValue = widget
                      .speedtestInstanceUrlNotifier
                      .value
                      .trim();
                  final bool isDefaultServer =
                      urlValue.isEmpty || urlValue == defaultSpeedtestServer;

                  if (isDefaultServer) {
                    bannerText = _appLocalizations.speedtestLibrespeed;
                  } else {
                    return const SizedBox.shrink();
                  }
                } else if (backend == 2) {
                  bannerText = _appLocalizations.speedtestOpenSpeedTest;
                }

                return Container(
                  width: double.maxFinite,
                  padding: EdgeInsets.fromLTRB(
                    12.0,
                    constraints.maxHeight < 640 ? 2.0 : 4.0,
                    12.0,
                    constraints.maxHeight < 640 ? 8.0 : 20.0,
                  ),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Color.alphaBlend(
                      Theme.of(context).colorScheme.primary
                          .withValues(alpha: 0.05),
                      Theme.of(context).colorScheme.surface,
                    ),
                  ),
                  child: Text(
                    bannerText,
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
