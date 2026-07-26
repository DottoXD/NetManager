import 'package:flutter/material.dart';
import 'package:netmanager/l10n/app_localizations.dart';
import 'package:netmanager/utils/haptic_service.dart';

class GraphsButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const GraphsButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      elevation: 1,
      mini: true,
      onPressed: () async {
        await HapticService().triggerHaptic(HapticType.light, context);

        onPressed!();
      },
      tooltip: AppLocalizations.of(context)!.homeGraphs,
      child: const Icon(Icons.ssid_chart_outlined),
    );
  }
}
