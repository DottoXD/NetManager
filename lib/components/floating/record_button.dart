import 'package:flutter/material.dart';
import 'package:netmanager/l10n/app_localizations.dart';
import 'package:netmanager/utils/haptic_service.dart';

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

        await HapticService().triggerHaptic(HapticType.selection, context);
        onPressed?.call();
      },
      tooltip: AppLocalizations.of(context)!.coverageRecording,
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
