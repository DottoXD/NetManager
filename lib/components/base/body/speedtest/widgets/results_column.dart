import 'package:flutter/material.dart';

Widget resultsColumn(
  BuildContext context,
  String label,
  double value,
  IconData icon,
  Color color,
) {
  return Expanded(
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
        Text(
          "${value.toStringAsFixed(1)} Mbps",
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}
