import 'package:flutter/material.dart';
import 'package:netmanager/components/base/body/speedtest/speedtest.dart';

Widget liveView(
  BuildContext context,
  TestStage stage,
  int ping,
  double currentSpeed,
) {
  bool showingLatency = stage == TestStage.LATENCY;
  return Column(
    key: const ValueKey("live"),
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        stage.name,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          letterSpacing: 4,
          fontWeight: FontWeight.bold,
          color: stage == TestStage.LATENCY
              ? Theme.of(context).colorScheme.secondary
              : (stage == TestStage.UPLOAD
                    ? Theme.of(context).colorScheme.tertiary
                    : Theme.of(context).colorScheme.primary),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        showingLatency
            ? "$ping"
            : currentSpeed.toStringAsFixed(currentSpeed > 10 ? 1 : 2),
        style: Theme.of(context).textTheme.displayLarge?.copyWith(
          fontSize: 72,
          fontWeight: FontWeight.w300,
          fontFeatures: [const FontFeature.tabularFigures()],
        ),
      ),
      Text(
        showingLatency ? "ms" : "Mbps",
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    ],
  );
}
