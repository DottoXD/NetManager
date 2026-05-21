import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum HapticType { SELECTION, LIGHT, MEDIUM, HEAVY }

Future<void> triggerHaptic(HapticType type, BuildContext? context) async {
  if (context != null && context.mounted) {
    try {
      await Feedback.forTap(context);
    } catch (e) {
      //todo
    }
  }

  switch (type) {
    case HapticType.SELECTION:
      await HapticFeedback.selectionClick();
      break;
    case HapticType.LIGHT:
      await HapticFeedback.lightImpact();
      break;
    case HapticType.MEDIUM:
      await HapticFeedback.mediumImpact();
      break;
    case HapticType.HEAVY:
      await HapticFeedback.heavyImpact();
      break;
  }
}
