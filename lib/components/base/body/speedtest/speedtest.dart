import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:netmanager/components/base/body/speedtest/widgets/hero_gauge.dart';
import 'package:netmanager/components/base/body/speedtest/widgets/quality_metrics.dart';
import 'package:netmanager/components/base/body/speedtest/widgets/speed_results.dart';
import 'package:netmanager/components/modals/server_modal.dart';

enum TestStage { IDLE, LATENCY, DOWNLOAD, UPLOAD, FINISHED }

class SpeedtestBody extends StatefulWidget {
  final MethodChannel platform;
  const SpeedtestBody(this.platform, {super.key});

  @override
  State<SpeedtestBody> createState() => _SpeedtestBodyState();
}

class _SpeedtestBodyState extends State<SpeedtestBody> {
  late MethodChannel platform;

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

  // todo: add server fetcher & "powered by librespeed" watermark for librespeed backends
  final List<dynamic> _servers = [
    {
      "name": "Roma (GARR)",
      "server": "https://st-be-rm2.infra.garr.it",
      "id": 35,
      "dlURL": "garbage.php",
      "ulURL": "empty.php",
      "pingURL": "empty.php",
    },
  ];

  @override
  void initState() {
    super.initState();
    platform = widget.platform;

    selectedServerNotifier.value = _servers[0];

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

  void _startTest() {
    if (selectedServerNotifier.value == null) return;

    setState(() {
      _stage = TestStage.LATENCY;
      _currentSpeed = 0.0;
      _maxSpeedScale = 100.0;
      _ping = 0;
      _jitter = 0;
    });

    String baseUrl = selectedServerNotifier.value!['server'];
    if (!baseUrl.endsWith('/')) baseUrl += '/';

    platform.invokeMethod("startTest", {
      "pingUrl": baseUrl + selectedServerNotifier.value!['pingURL'],
      "downloadUrl": baseUrl + selectedServerNotifier.value!['dlURL'],
      "uploadUrl": baseUrl + selectedServerNotifier.value!['ulURL'],
    });
  }

  @override
  Widget build(BuildContext context) {
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
                        label: Text(selectedServer!['name']),
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
      ],
    );
  }
}
