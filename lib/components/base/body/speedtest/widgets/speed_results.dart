import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:netmanager/components/base/body/speedtest/widgets/results_column.dart';
import 'package:netmanager/components/base/body/speedtest/speedtest.dart';
import 'package:netmanager/l10n/app_localizations.dart';
import 'package:netmanager/utils/haptic_service.dart';

class SpeedResults extends StatelessWidget {
  final TestStage stage;
  final double downloadResult;
  final double uploadResult;
  final double progress;
  final VoidCallback startTest;
  final int unitIndex;
  final bool isCompact;

  const SpeedResults({
    super.key,
    required this.stage,
    required this.downloadResult,
    required this.uploadResult,
    required this.progress,
    required this.startTest,
    required this.unitIndex,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    AppLocalizations appLocalizations = AppLocalizations.of(context)!;

    bool isRunning = stage != TestStage.IDLE && stage != TestStage.FINISHED;

    Color progressColor;
    if (stage == TestStage.DOWNLOAD) {
      progressColor = Theme.of(context).colorScheme.primary;
    } else if (stage == TestStage.UPLOAD) {
      progressColor = Theme.of(context).colorScheme.tertiary;
    } else {
      progressColor = Theme.of(context).colorScheme.secondary;
    }

    const topRadius = BorderRadius.vertical(top: Radius.circular(24));

    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(30.0, 24.0, 24.0, 24.0),
          decoration: BoxDecoration(
            borderRadius: topRadius,
            color: Theme.of(context).colorScheme.surfaceContainerLow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isCompact) ...[
                Row(
                  children: [
                    ResultsColumn(
                      label: "DOWNLOAD",
                      value: downloadResult,
                      icon: Icons.south_outlined,
                      color: Theme.of(context).colorScheme.primary,
                      unitIndex: unitIndex,
                    ),
                    ResultsColumn(
                      label: "UPLOAD",
                      value: uploadResult,
                      icon: Icons.north_outlined,
                      color: Theme.of(context).colorScheme.tertiary,
                      unitIndex: unitIndex,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: isRunning
                      ? null
                      : () async {
                          await HapticService().triggerHaptic(
                            HapticType.light,
                            context,
                          );

                          startTest();
                        },
                  child: Text(
                    isRunning
                        ? appLocalizations.speedtestRunning
                        : appLocalizations.speedtestStart,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (progress > 0)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 32,
            child: ClipRRect(
              borderRadius: topRadius,
              child: TweenAnimationBuilder(
                tween: Tween(begin: 0.0, end: progress.clamp(0.0, 1.0)),
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOutCubic,
                builder: (context, animatedProgress, child) {
                  return Stack(
                    children: [
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: ImageFiltered(
                          imageFilter: ImageFilter.blur(
                            sigmaX: 5.0,
                            sigmaY: 5.0,
                          ),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: FractionallySizedBox(
                              widthFactor: animatedProgress,
                              child: AnimatedContainer(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(1.5),
                                  color: progressColor,
                                ),
                                duration: const Duration(milliseconds: 200),
                                height: 3.0,
                                color: progressColor,
                                alignment: Alignment.centerLeft,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.topLeft,
                        child: FractionallySizedBox(
                          widthFactor: animatedProgress,
                          child: AnimatedContainer(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(1.5),
                              color: progressColor,
                            ),
                            duration: const Duration(milliseconds: 200),
                            height: 3.0,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
