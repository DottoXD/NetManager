import 'package:flutter/material.dart';

Widget summaryView(
  BuildContext context,
  double downloadResult,
  double uploadResult,
) {
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
            downloadResult.toStringAsFixed(1),
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 4),
          Text("Mbps", style: Theme.of(context).textTheme.labelSmall),
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
            uploadResult.toStringAsFixed(1),
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 4),
          Text("Mbps", style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        "COMPLETED",
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          letterSpacing: 2,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    ],
  );
}
