import 'package:flutter/material.dart';

class QualityMetrics extends StatelessWidget {
  final int ping;
  final int jitter;
  final double packetLoss;

  const QualityMetrics({
    super.key,
    required this.ping,
    required this.jitter,
    required this.packetLoss,
  });

  @override
  Widget build(BuildContext context) {
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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
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
}
