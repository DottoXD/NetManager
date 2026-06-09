import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:netmanager/components/dialogs/error.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum HapticType { SELECTION, LIGHT, MEDIUM, HEAVY }

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

    if (context != null && context.mounted) {
      try {
        await Feedback.forTap(context);
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
}
