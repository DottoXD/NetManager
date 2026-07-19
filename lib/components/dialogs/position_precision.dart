import 'package:flutter/material.dart';
import 'package:netmanager/l10n/app_localizations.dart';
import 'package:netmanager/utils/haptic_service.dart';

class PositionPrecisionDialog extends StatelessWidget {
  const PositionPrecisionDialog({
    super.key,
    required this.positionPrecisions,
    required this.currentSelection,
    required this.onChanged,
  });

  final List<String> positionPrecisions;
  final String currentSelection;
  final Function(int index, String value) onChanged;

  @override
  Widget build(BuildContext context) {
    AppLocalizations appLocalizations = AppLocalizations.of(context)!;

    String tempSelection = currentSelection;

    return AlertDialog(
      title: Text(appLocalizations.editPositionPrecision),
      content: SingleChildScrollView(
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return ListBody(
              children: positionPrecisions.asMap().entries.map((precision) {
                return RadioListTile(
                  title: Text(precision.value),
                  value: precision.value,
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

            final finalIndex = positionPrecisions.indexOf(tempSelection);
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
