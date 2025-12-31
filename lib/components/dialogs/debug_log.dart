import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

Widget debugLogDialog(
  BuildContext context,
  List<String> debugLogsList,
  MethodChannel platform,
) {
  final outlineVariant = Theme.of(context).colorScheme.outlineVariant;

  if (debugLogsList.isEmpty) throw "No debug logs";

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
                  Text(debugLogsList[debugLogsList.length - 1 - i]),
                  if (i < debugLogsList.length - 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Divider(height: 0, color: outlineVariant),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    ),
    actions: [
      TextButton.icon(
        onPressed: () async {
          final dir = await getExternalStorageDirectory();

          if (dir == null) {
            await platform.invokeMethod<bool>("showToast", {
              "message": "External storage is unavailable!",
            });
            return;
          }

          final file = File("${dir.path}/debug_logs.txt");
          final content = debugLogsList.join("\n");
          await file.writeAsString(content);

          await platform.invokeMethod<bool>("showToast", {
            "message": "Debug logs saved at: ${file.path}",
          });
        },
        label: const Text("Export"),
        icon: const Icon(Icons.share),
      ),
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text("Close"),
      ),
    ],
  );
}
