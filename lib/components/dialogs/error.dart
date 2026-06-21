import 'package:flutter/material.dart';
import 'package:netmanager/l10n/app_localizations.dart';
import 'package:netmanager/utils/haptic_service.dart';

Widget errorDialog(BuildContext context, Object e) {
  AppLocalizations appLocalizations = AppLocalizations.of(context)!;
  HapticService().triggerHaptic(HapticType.medium, context);

  return AlertDialog(
    title: Text(appLocalizations.error),
    content: SizedBox(
      width: double.maxFinite,
      child: Scrollbar(child: Text(e.toString())),
    ),
    actions: [
      FilledButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(appLocalizations.close),
      ),
    ],
  );
}
