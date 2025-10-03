import 'package:flutter/material.dart';

class PositionButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const PositionButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      elevation: 1,
      onPressed: onPressed,
      tooltip: 'Reposition location',
      child: const Icon(Icons.location_searching_rounded),
    );
  }
}
