import 'package:flutter/material.dart';
import 'package:netmanager/l10n/app_localizations.dart';
import 'package:netmanager/utils/haptic_service.dart';

Widget speedMeasurementUnitDialog(
  BuildContext context,
  List<String> speedMeasurementUnits,
  String currentSelection,
  Function(int index, String value) onChanged,
) {
  AppLocalizations appLocalizations = AppLocalizations.of(context)!;

  return AlertDialog(
    title: Text(appLocalizations.editSpeedMeasurementUnit),
    content: SingleChildScrollView(
      child: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return ListBody(
            children: speedMeasurementUnits.asMap().entries.map((unit) {
              return RadioListTile(
                title: Text(unit.value),
                value: unit.value,
                groupValue: currentSelection,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      currentSelection = value.toString();
                    });
                    onChanged(unit.key, value.toString());
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

          if (context.mounted) Navigator.of(context).pop();
        },
      ),
    ],
  );
}
