import 'package:material_ui/material_ui.dart';
import 'package:netmanager/l10n/app_localizations.dart';
import 'package:netmanager/utils/haptic_service.dart';

class ErrorDialog extends StatelessWidget {
  const ErrorDialog({super.key, required this.e});

  final Object e;

  @override
  Widget build(BuildContext context) {
    AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    HapticService().triggerHaptic(HapticType.medium, context);

    return AlertDialog(
      title: Text(appLocalizations.error),
      content: SizedBox(
        width: double.maxFinite,
        child: Scrollbar(
          child: SingleChildScrollView(child: Text(e.toString())),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(appLocalizations.close),
        ),
      ],
    );
  }
}
