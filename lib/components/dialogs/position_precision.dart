import 'package:flutter/material.dart';

Widget positionPrecisionDialog(
  BuildContext context,
  List<String> positionPrecisions,
  String currentSelection,
  Function(int index, String value) onChanged,
) {
  return AlertDialog(
    title: const Text('Edit position precision'),
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
      FilledButton(
        child: const Text('Edit'),
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
    ],
  );
}
