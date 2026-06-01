import 'package:flutter/material.dart';
import 'package:netmanager/components/utils/speed_methods.dart';

class ResultsColumn extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  final Color color;
  final int unitIndex;

  const ResultsColumn({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.unitIndex,
  });

  @override
  Widget build(BuildContext context) {
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
}
