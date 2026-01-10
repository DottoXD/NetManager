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
      onTap: () {
        triggerHaptic(type);
        onTap?.call();
      },
      child: child,
    );
  }
}

void triggerHaptic(HapticType type) {
  switch (type) {
    case HapticType.SELECTION:
      HapticFeedback.selectionClick();
      break;
    case HapticType.LIGHT:
      HapticFeedback.lightImpact();
      break;
    case HapticType.MEDIUM:
      HapticFeedback.mediumImpact();
      break;
    case HapticType.HEAVY:
      HapticFeedback.heavyImpact();
      break;
  }
}
