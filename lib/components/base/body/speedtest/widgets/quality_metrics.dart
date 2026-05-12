import 'package:flutter/material.dart';

Widget qualityMetrics(
  BuildContext context,
  int ping,
  int jitter,
  double packetLoss,
) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    children: [
      for (final (label, value, unit) in [
        ("PING", "$ping", "ms"),
        ("JITTER", "$jitter", "ms"),
        ("LOSS", packetLoss.toStringAsFixed(1), "%"),
      ])
        Column(
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 2),
                Text(unit, style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ],
        ),
    ],
  );
}
