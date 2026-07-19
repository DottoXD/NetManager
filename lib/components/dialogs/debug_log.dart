import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:netmanager/l10n/app_localizations.dart';
import 'package:netmanager/utils/haptic_service.dart';
import 'package:path_provider/path_provider.dart';

class DebugLogDialog extends StatelessWidget {
  const DebugLogDialog({
    super.key,
    required this.debugLogsList,
    required this.platform,
  });

  final List<String> debugLogsList;
  final MethodChannel platform;

  @override
  Widget build(BuildContext context) {
    AppLocalizations appLocalizations = AppLocalizations.of(context)!;

    final outlineVariant = Theme.of(context).colorScheme.outlineVariant;

    if (debugLogsList.isEmpty) throw appLocalizations.noDebugLogs;

    return AlertDialog(
      title: Text(appLocalizations.debugLogs),
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
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(appLocalizations.close),
        ),
        FilledButton.icon(
          onPressed: () async {
            await HapticService().triggerHaptic(HapticType.selection, context);

            final dir = await getTemporaryDirectory();
            final exportFolder = Directory("${dir.path}/exports");
            if (!exportFolder.existsSync()) {
              await exportFolder.create();
            }

            final file = File("${exportFolder.path}/debug_logs.txt");
            final content = debugLogsList.join("\n");
            await file.writeAsString(content);

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(appLocalizations.debugLogsSaved(file.path)),
                  showCloseIcon: true,
                ),
              );
            }

            await platform.invokeMethod("share", {"path": file.path});
          },
          label: Text(appLocalizations.export),
          icon: const Icon(Icons.offline_share_outlined),
        ),
      ],
    );
  }
}
