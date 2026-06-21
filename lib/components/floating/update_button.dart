import 'package:flutter/material.dart';
import 'package:netmanager/l10n/app_localizations.dart';
import 'package:netmanager/utils/haptic_service.dart';

class UpdateButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const UpdateButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      elevation: 1,
      onPressed: () async {
        await HapticService().triggerHaptic(HapticType.light, context);
        onPressed!();
      },
      tooltip: AppLocalizations.of(context)!.updateData,
      child: const Icon(Icons.update_outlined),
    );
  }
}
