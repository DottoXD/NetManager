import 'package:flutter/material.dart';

Widget errorDialog(BuildContext context, Object e) {
  return AlertDialog(
    title: const Text("Error"),
    content: SizedBox(
      width: double.maxFinite,
      child: Scrollbar(child: Text(e.toString())),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text("Close"),
      ),
    ],
  );
}
