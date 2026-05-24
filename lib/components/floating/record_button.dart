import 'package:flutter/material.dart';
import 'package:netmanager/components/utils/haptic_service.dart';

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
        if (onPressed == null) return;

        await HapticService().triggerHaptic(HapticType.SELECTION, context);
        onPressed?.call();
      },
      tooltip: 'Cell coverage recording',
      child: ValueListenableBuilder(
        valueListenable: recordingActionNotifier,
        builder: (context, isRecording, child) {
          return Icon(
            isRecording
                ? Icons.close_outlined
                : Icons.fiber_smart_record_outlined,
            size: 18,
          );
        },
      ),
    );
  }
}
