import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:netmanager/components/base/body/speedtest/widgets/live_view.dart';
import 'package:netmanager/components/base/body/speedtest/speedtest.dart';
import 'package:netmanager/components/base/body/speedtest/widgets/summary_view.dart';
import 'package:netmanager/components/utils/speed_methods.dart';

class HeroGauge extends StatelessWidget {
  final TestStage stage;
  final double latencyProgress;
  final double currentSpeed;
  final double maxSpeedScale;
  final int ping;
  final double downloadResult;
  final double uploadResult;
  final int unitIndex;

  const HeroGauge({
    super.key,
    required this.stage,
    required this.latencyProgress,
    required this.currentSpeed,
    required this.maxSpeedScale,
    required this.ping,
    required this.downloadResult,
    required this.uploadResult,
    required this.unitIndex,
  });

  @override
  Widget build(BuildContext context) {
    bool isLatency = stage == TestStage.LATENCY;
    bool isFinished = stage == TestStage.FINISHED;

    double gaugePercentage;
    if (isLatency) {
      gaugePercentage = latencyProgress;
    } else {
      gaugePercentage = (currentSpeed / maxSpeedScale).clamp(0.0, 1.0);
    }

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 280,
            height: 280,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 8,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
          SizedBox(
            width: 280,
            height: 280,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: 0,
                end: isFinished ? 0 : gaugePercentage,
              ),
              duration: Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                final baseColor = stage == TestStage.LATENCY
                    ? Theme.of(context).colorScheme.secondary
                    : (stage == TestStage.UPLOAD
                          ? Theme.of(context).colorScheme.tertiary
                          : Theme.of(context).colorScheme.primary);

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                        child: Transform.translate(
                          offset: const Offset(0, 4),
                          child: CircularProgressIndicator(
                            value: value,
                            strokeWidth: 14,
                            strokeCap: StrokeCap.square,
                            color: baseColor.withValues(alpha: 0.25),
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: CircularProgressIndicator(
                        value: value,
                        strokeWidth: 12,
                        strokeCap: StrokeCap.round,
                        color: baseColor,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          if (stage == TestStage.DOWNLOAD || stage == TestStage.UPLOAD)
            Positioned(
              bottom: 40,
              child: Text(
                "0 — ${formatSpeed(maxSpeedScale, unitIndex)} ${getUnitString(unitIndex)}",
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: isFinished
                ? SummaryView(
                    downloadResult: downloadResult,
                    uploadResult: uploadResult,
                    unitIndex: unitIndex,
                  )
                : LiveView(
                    stage: stage,
                    ping: ping,
                    currentSpeed: currentSpeed,
                    unitIndex: unitIndex,
                  ),
          ),
        ],
      ),
    );
  }
}
