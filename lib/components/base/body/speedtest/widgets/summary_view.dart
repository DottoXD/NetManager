import 'package:flutter/material.dart';
import 'package:netmanager/l10n/app_localizations.dart';
import 'package:netmanager/utils/speed_methods.dart';

class SummaryView extends StatelessWidget {
  final double downloadResult;
  final double uploadResult;
  final int unitIndex;

  const SummaryView({
    super.key,
    required this.downloadResult,
    required this.uploadResult,
    required this.unitIndex,
  });

  @override
  Widget build(BuildContext context) {
    AppLocalizations appLocalizations = AppLocalizations.of(context)!;

    return Column(
      key: const ValueKey("summary"),
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.check_circle_outline_outlined,
          color: Theme.of(context).colorScheme.primary,
          size: 32,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.south_outlined,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              formatSpeed(downloadResult, unitIndex),
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 4),
            Text(
              getUnitString(unitIndex),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.north_outlined,
              size: 16,
              color: Theme.of(context).colorScheme.tertiary,
            ),
            const SizedBox(width: 8),
            Text(
              formatSpeed(uploadResult, unitIndex),
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 4),
            Text(
              getUnitString(unitIndex),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          appLocalizations.speedtestCompleted,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            letterSpacing: 2,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ],
    );
  }
}
