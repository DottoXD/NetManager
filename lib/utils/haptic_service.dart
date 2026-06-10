import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum HapticType { selection, light, medium, heavy }

class HapticService {
  static final HapticService _instance = HapticService._internal();
  factory HapticService() => _instance;
  HapticService._internal();

  bool _hapticEnabled = true;

  Future<void> init(SharedPreferences prefs) async {
    _hapticEnabled = prefs.getBool("hapticFeedback") ?? true;
  }

  Future<void> setHapticEnabled(bool enabled) async {
    _hapticEnabled = enabled;
  }

  Future<void> triggerHaptic(HapticType type, BuildContext? context) async {
    if (!_hapticEnabled) return;

    /*if (context != null && context.mounted) {
      try {
        if (Scrollable.maybeOf(context) != null) await Feedback.forTap(context);
      } catch (e) {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return errorDialog(context, "Haptic service: $e");
            },
          );
        }
      }
    }*/

    switch (type) {
      case HapticType.selection:
        await HapticFeedback.selectionClick();
        break;
      case HapticType.light:
        await HapticFeedback.lightImpact();
        break;
      case HapticType.medium:
        await HapticFeedback.mediumImpact();
        break;
      case HapticType.heavy:
        await HapticFeedback.heavyImpact();
        break;
    }
  }
}
