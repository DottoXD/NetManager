import 'package:flutter/material.dart';
import 'package:netmanager/l10n/app_localizations.dart';
import 'package:netmanager/utils/haptic_service.dart';

class PositionButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const PositionButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      elevation: 1,
      onPressed: () async {
        await HapticService().triggerHaptic(HapticType.light, context);
        onPressed!();
      },
      tooltip: AppLocalizations.of(context)!.repositionMap,
      child: const Icon(Icons.location_searching_outlined),
    );
  }
}
