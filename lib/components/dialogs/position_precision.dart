import 'package:flutter/material.dart';
import 'package:netmanager/l10n/app_localizations.dart';
import 'package:netmanager/utils/haptic_service.dart';

Widget positionPrecisionDialog(
  BuildContext context,
  List<String> positionPrecisions,
  String currentSelection,
  Function(int index, String value) onChanged,
) {
  AppLocalizations appLocalizations = AppLocalizations.of(context)!;

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
                groupValue: currentSelection,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      currentSelection = value.toString();
                    });
                    onChanged(precision.key, value.toString());
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
