import 'package:flutter/material.dart';
import 'package:netmanager/components/utils/haptic_utils.dart';

class ScreenshotButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const ScreenshotButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return HapticTap(
      type: HapticType.SELECTION,
      child: FloatingActionButton(
        elevation: 1,
        mini: true,
        onPressed: onPressed,
        tooltip: 'Screenshot page',
        child: const Icon(Icons.save_outlined, size: 18),
      ),
    );
  }
}
