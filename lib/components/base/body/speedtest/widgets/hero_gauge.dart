import 'package:flutter/material.dart';
import 'package:netmanager/components/base/body/speedtest/widgets/live_view.dart';
import 'package:netmanager/components/base/body/speedtest/speedtest.dart';
import 'package:netmanager/components/base/body/speedtest/widgets/summary_view.dart';

Widget heroGauge(
  BuildContext context,
  TestStage stage,
  double latencyProgress,
  double currentSpeed,
  double maxSpeedScale,
  int ping,
  double downloadResult,
  double uploadResult,
) {
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
            duration: Duration(milliseconds: isLatency ? 200 : 400),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) => CircularProgressIndicator(
              value: value,
              strokeWidth: 12,
              strokeCap: StrokeCap.round,
              color: stage == TestStage.LATENCY
                  ? Theme.of(context).colorScheme.secondary
                  : (stage == TestStage.UPLOAD
                        ? Theme.of(context).colorScheme.tertiary
                        : Theme.of(context).colorScheme.primary),
            ),
          ),
        ),
        if (stage == TestStage.DOWNLOAD || stage == TestStage.UPLOAD)
          Positioned(
            bottom: 40,
            child: Text(
              "0 — ${maxSpeedScale.toInt()} Mbps",
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: isFinished
              ? summaryView(context, downloadResult, uploadResult)
              : liveView(context, stage, ping, currentSpeed),
        ),
      ],
    ),
  );
}
