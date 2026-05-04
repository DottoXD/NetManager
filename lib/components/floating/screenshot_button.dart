import 'package:flutter/material.dart';
import 'package:netmanager/components/utils/haptic_utils.dart';

class ScreenshotButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const ScreenshotButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      elevation: 1,
      mini: true,
      onPressed: () async {
        await triggerHaptic(HapticType.SELECTION, context);
        onPressed!();
      },
      tooltip: 'Screenshot page',
      child: const Icon(Icons.save_outlined, size: 18),
    );
  }
}
