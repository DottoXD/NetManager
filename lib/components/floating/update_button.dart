import 'package:flutter/material.dart';
import 'package:netmanager/components/utils/haptic_utils.dart';

class UpdateButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const UpdateButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return HapticTap(
      type: HapticType.LIGHT,
      child: FloatingActionButton(
        elevation: 1,
        onPressed: onPressed,
        tooltip: 'Update data',
        child: const Icon(Icons.update_rounded),
      ),
    );
  }
}
