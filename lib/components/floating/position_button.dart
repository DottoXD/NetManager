import 'package:flutter/material.dart';

class PositionButton extends StatelessWidget {
  const PositionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      elevation: 1,
      onPressed: null,
      tooltip: 'Update location',
      child: const Icon(Icons.location_searching_rounded),
    );
  }
}
