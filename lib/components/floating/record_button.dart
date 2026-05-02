import 'package:flutter/material.dart';
import 'package:netmanager/components/utils/haptic_utils.dart';

class RecordButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const RecordButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return HapticTap(
      type: HapticType.SELECTION,
      child: FloatingActionButton(
        elevation: 1,
        mini: true,
        onPressed: onPressed,
        tooltip: 'Cell coverage recording',
        child: const Icon(Icons.fiber_manual_record_outlined, size: 18),
      ),
    );
  }
}
