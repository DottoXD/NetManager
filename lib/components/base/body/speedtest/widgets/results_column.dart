import 'package:flutter/material.dart';
import 'package:netmanager/components/utils/speed_methods.dart';

Widget resultsColumn(
  BuildContext context,
  String label,
  double value,
  IconData icon,
  Color color,
  int unitIndex,
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
          "${formatSpeed(value, unitIndex)} ${getUnitString(unitIndex)}",
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}
