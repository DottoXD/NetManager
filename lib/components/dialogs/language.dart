import 'package:material_ui/material_ui.dart';
import 'package:netmanager/l10n/app_localizations.dart';
import 'package:netmanager/utils/haptic_service.dart';
import 'package:netmanager/utils/language_name.dart';

class LanguageDialog extends StatelessWidget {
  const LanguageDialog({
    super.key,
    required this.currentLocale,
    required this.onLocaleConfirmed,
  });

  final Locale? currentLocale;
  final ValueChanged<Locale?> onLocaleConfirmed;

  @override
  Widget build(BuildContext context) {
    AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    Locale? tempSelectedLocale = currentLocale;

    return AlertDialog(
      title: Text(appLocalizations.editLanguage),
      content: SingleChildScrollView(
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return ListBody(
              children: [
                RadioListTile<String?>(
                  title: Text(appLocalizations.systemLanguage),
                  value: null,
                  groupValue: tempSelectedLocale?.languageCode,
                  onChanged: (value) {
                    setState(() => tempSelectedLocale = null);
                  },
                ),
                ...AppLocalizations.supportedLocales.map((Locale locale) {
                  return RadioListTile<String>(
                    title: Text(getLanguageName(locale.languageCode)),
                    value: locale.languageCode,
                    groupValue: tempSelectedLocale?.languageCode,
                    onChanged: (value) {
                      setState(() => tempSelectedLocale = locale);
                    },
                  );
                }),
              ],
            );
          },
        ),
      ),
      actions: <Widget>[
        FilledButton.icon(
          icon: const Icon(Icons.edit_outlined),
          label: Text(appLocalizations.edit),
          onPressed: () async {
            await HapticService().triggerHaptic(HapticType.selection, context);

            onLocaleConfirmed(tempSelectedLocale);

            if (context.mounted) Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
