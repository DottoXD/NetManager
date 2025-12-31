import 'package:flutter/material.dart';

class ScreenshotButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const ScreenshotButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      elevation: 1,
      mini: true,
      onPressed: onPressed,
      tooltip: 'Screenshot page',
      child: const Icon(Icons.save_outlined, size: 18),
    );
  }
}
