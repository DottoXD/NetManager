import 'package:flutter/material.dart';
import 'package:netmanager/components/base/body/speedtest/widgets/results_column.dart';
import 'package:netmanager/components/base/body/speedtest/speedtest.dart';

Widget speedResults(
  BuildContext context,
  TestStage stage,
  double downloadResult,
  double uploadResult,
  VoidCallback startTest,
) {
  bool isRunning = stage != TestStage.IDLE && stage != TestStage.FINISHED;

  return Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            resultsColumn(
              context,
              "DOWNLOAD",
              downloadResult,
              Icons.south_outlined,
              Theme.of(context).colorScheme.primary,
            ),
            resultsColumn(
              context,
              "UPLOAD",
              uploadResult,
              Icons.north_outlined,
              Theme.of(context).colorScheme.tertiary,
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton(
            onPressed: isRunning ? null : startTest,
            child: Text(isRunning ? "Running..." : "Start Speed test"),
          ),
        ),
      ],
    ),
  );
}
