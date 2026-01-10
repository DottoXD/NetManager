import 'package:flutter/material.dart';
import 'package:netmanager/components/utils/haptic_utils.dart';

class PositionButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const PositionButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return HapticTap(
      type: HapticType.LIGHT,
      child: FloatingActionButton(
        elevation: 1,
        onPressed: onPressed,
        tooltip: 'Reposition location',
        child: const Icon(Icons.location_searching_rounded),
      ),
    );
  }
}
