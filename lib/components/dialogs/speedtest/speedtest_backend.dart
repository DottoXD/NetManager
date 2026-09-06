import 'package:material_ui/material_ui.dart';
import 'package:netmanager/l10n/app_localizations.dart';
import 'package:netmanager/utils/haptic_service.dart';

class SpeedtestBackendDialog extends StatelessWidget {
  const SpeedtestBackendDialog({
    super.key,
    required this.speedtestBackends,
    required this.currentSelection,
    required this.onChanged,
  });

  final List<String> speedtestBackends;
  final String currentSelection;
  final Function(int index, String value) onChanged;

  @override
  Widget build(BuildContext context) {
    AppLocalizations appLocalizations = AppLocalizations.of(context)!;

    String tempSelection = currentSelection;

    return AlertDialog(
      title: Text(appLocalizations.editSpeedtestBackend),
      content: SingleChildScrollView(
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return ListBody(
              children: speedtestBackends.asMap().entries.map((backend) {
                return RadioListTile(
                  title: Text(backend.value),
                  value: backend.value,
                  groupValue: tempSelection,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        tempSelection = value.toString();
                      });
                    }
                  },
                );
              }).toList(),
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

            final finalIndex = speedtestBackends.indexOf(tempSelection);
            if (finalIndex != -1) {
              onChanged(finalIndex, tempSelection);
            }

            if (context.mounted) Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
