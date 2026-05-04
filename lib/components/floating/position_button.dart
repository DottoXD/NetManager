import 'package:flutter/material.dart';
import 'package:netmanager/components/utils/haptic_utils.dart';

class PositionButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const PositionButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      elevation: 1,
      onPressed: () async {
        await triggerHaptic(HapticType.LIGHT, context);
        onPressed!();
      },
      tooltip: 'Reposition location',
      child: const Icon(Icons.location_searching_rounded),
    );
  }
}
