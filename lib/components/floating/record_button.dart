import 'package:flutter/material.dart';
import 'package:netmanager/components/utils/haptic_utils.dart';

class RecordButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final ValueNotifier<bool> recordingActionNotifier;

  const RecordButton({
    super.key,
    this.onPressed,
    required this.recordingActionNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      elevation: 1,
      mini: true,
      onPressed: () async {
        await triggerHaptic(HapticType.SELECTION, context);
        onPressed!();
      },
      tooltip: 'Cell coverage recording',
      child: Icon(
        recordingActionNotifier.value
            ? Icons.close_outlined
            : Icons.fiber_smart_record_outlined,
        size: 18,
      ),
    );
  }
}
