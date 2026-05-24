import 'package:netmanager/components/base/body/speedtest/speedtest.dart';

class SpeedtestMetrics {
  final TestStage stage;
  final double currentSpeed;
  final int ping;
  final double latencyProgress;
  final int jitter;
  final double packetLoss;
  final double downloadResult;
  final double uploadResult;
  final double maxSpeedScale;
  final double progress;

  SpeedtestMetrics({
    this.stage = TestStage.IDLE,
    this.currentSpeed = 0.0,
    this.ping = 0,
    this.latencyProgress = 0.0,
    this.jitter = 0,
    this.packetLoss = 0.0,
    this.downloadResult = 0.0,
    this.uploadResult = 0.0,
    this.maxSpeedScale = 100.0,
    this.progress = 0.0,
  });

  SpeedtestMetrics copyWith({
    TestStage? stage,
    double? currentSpeed,
    int? ping,
    double? latencyProgress,
    int? jitter,
    double? packetLoss,
    double? downloadResult,
    double? uploadResult,
    double? maxSpeedScale,
    double? progress,
  }) {
    return SpeedtestMetrics(
      stage: stage ?? this.stage,
      currentSpeed: currentSpeed ?? this.currentSpeed,
      ping: ping ?? this.ping,
      latencyProgress: latencyProgress ?? this.latencyProgress,
      jitter: jitter ?? this.jitter,
      packetLoss: packetLoss ?? this.packetLoss,
      downloadResult: downloadResult ?? this.downloadResult,
      uploadResult: uploadResult ?? this.uploadResult,
      maxSpeedScale: maxSpeedScale ?? this.maxSpeedScale,
      progress: progress ?? this.progress,
    );
  }
}
