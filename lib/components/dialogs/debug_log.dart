import 'package:flutter/material.dart';

Widget debugLogDialog(BuildContext context, List<String> debugLogsList) {
  return AlertDialog(
    title: Text("Debug Logs"),
    content: SizedBox(
      width: double.maxFinite,
      child: Scrollbar(
        child: ListView.builder(
          itemCount: debugLogsList.length,
          itemBuilder: (context, i) {
            return ListTile(
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(debugLogsList[i]),
                  if (i < debugLogsList.length - 1)
                    Padding(
                      padding: EdgeInsets.only(top: 10.0),
                      child: Divider(
                        height: 0,
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text("Close"),
      ),
    ],
  );
}
