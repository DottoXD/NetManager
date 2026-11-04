import 'package:material_ui/material_ui.dart';
import 'package:netmanager/l10n/app_localizations.dart';
import 'package:netmanager/utils/haptic_service.dart';

class CarrierConfigEditDialog extends StatelessWidget {
  const CarrierConfigEditDialog({
    super.key,
    required this.featureTitle,
    required this.currentValue,
    required this.options,
  });

  final String featureTitle;
  final String currentValue;
  final List<(String, String)> options;

  static Future<String?> show(
    BuildContext context, {
    required String featureTitle,
    required String currentValue,
    required List<(String, String)> options,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => CarrierConfigEditDialog(
        featureTitle: featureTitle,
        currentValue: currentValue,
        options: options,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations appLocalizations = AppLocalizations.of(context)!;

    String tempSelection = currentValue;

    return AlertDialog(
      title: Text(appLocalizations.advancedModeCarrierEditTitle),
      content: SingleChildScrollView(
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    featureTitle,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                ...options.map((option) {
                  return RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    title: Text(option.$2),
                    value: option.$1,
                    groupValue: tempSelection,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          tempSelection = value;
                        });
                      }
                    },
                  );
                }),
                const SizedBox(height: 8),
                Text(
                  appLocalizations.advancedModeCarrierEditNote,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
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

            if (context.mounted) {
              Navigator.of(context).pop(tempSelection);
            }
          },
        ),
      ],
    );
  }
}
