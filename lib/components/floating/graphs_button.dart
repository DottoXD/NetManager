import 'package:flutter/material.dart';
import 'package:netmanager/utils/haptic_service.dart';

class GraphsButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const GraphsButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      elevation: 1,
      onPressed: () async {
        await HapticService().triggerHaptic(HapticType.light, context);

        onPressed!();
      },
      child: const Icon(Icons.ssid_chart_outlined),
    );
  }
}
