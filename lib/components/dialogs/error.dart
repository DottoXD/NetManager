import 'package:flutter/material.dart';
import 'package:netmanager/components/utils/haptic_utils.dart';

Widget errorDialog(BuildContext context, Object e) {
  triggerHaptic(HapticType.MEDIUM, context);

  return AlertDialog(
    title: const Text("Error"),
    content: SizedBox(
      width: double.maxFinite,
      child: Scrollbar(child: Text(e.toString())),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text("Close"),
      ),
    ],
  );
}
