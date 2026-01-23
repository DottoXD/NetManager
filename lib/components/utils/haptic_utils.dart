import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum HapticType { SELECTION, LIGHT, MEDIUM, HEAVY }

class HapticTap extends StatelessWidget {
  final Widget child;
  final HapticType type;
  final VoidCallback? onTap;

  const HapticTap({
    super.key,
    required this.child,
    this.onTap,
    this.type = HapticType.SELECTION,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () async {
        await triggerHaptic(type);
        onTap?.call();
      },
      child: child,
    );
  }
}

Future<void> triggerHaptic(HapticType type) async {
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
