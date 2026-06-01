import 'package:flutter/material.dart';

class LocationDot extends StatelessWidget {
  const LocationDot({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.primaryContainer.withValues(alpha: 0.9),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white, //color to be changed
          width: 2,
        ),
      ),
    );
  }
}
