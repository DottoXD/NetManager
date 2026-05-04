import 'package:flutter/material.dart';
import 'package:netmanager/components/utils/haptic_utils.dart';

class UpdateButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const UpdateButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      elevation: 1,
      onPressed: () async {
        await triggerHaptic(HapticType.LIGHT, context);
        onPressed!();
      },
      tooltip: 'Update data',
      child: const Icon(Icons.update_rounded),
    );
  }
}
