import 'package:material_ui/material_ui.dart';
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
