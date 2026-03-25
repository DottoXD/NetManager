import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:netmanager/components/utils/haptic_utils.dart';
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
      HapticTap(
        type: HapticType.SELECTION,
        child: TextButton.icon(
          onPressed: () async {
            final dir = await getTemporaryDirectory();

            final exportFolder = Directory("${dir.path}/exports");
            if (!await exportFolder.exists()) {
              await exportFolder.create();
            }

            final file = File("${exportFolder.path}/debug_logs.txt");
            final content = debugLogsList.join("\n");
            await file.writeAsString(content);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Debug logs saved at: ${file.path}"),
                showCloseIcon: true,
              ),
            );

            await platform.invokeMethod("share", {"path": file.path});
          },
          label: const Text("Export"),
          icon: const Icon(Icons.share),
        ),
      ),
      HapticTap(
        type: HapticType.SELECTION,
        child: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Close"),
        ),
      ),
    ],
  );
}
