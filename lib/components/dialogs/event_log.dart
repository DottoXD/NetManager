import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:netmanager/l10n/app_localizations.dart';
import 'package:netmanager/utils/haptic_service.dart';
import 'package:netmanager/types/events/event_types.dart';
import 'package:netmanager/types/events/mobile_netmanager_event.dart';
import 'package:netmanager/types/events/netmanager_event.dart';
import 'package:path_provider/path_provider.dart';

class EventLogDialog extends StatelessWidget {
  const EventLogDialog({
    super.key,
    required this.events,
    required this.platform,
  });

  final List<NetmanagerEvent> events;
  final MethodChannel platform;
  @override
  Widget build(BuildContext context) {
    AppLocalizations appLocalizations = AppLocalizations.of(context)!;

    final formatter = DateFormat("dd/MM/yyyy HH:mm:ss");
    final outlineVariant = Theme.of(context).colorScheme.outlineVariant;

    return AlertDialog(
      title: Text(appLocalizations.eventLogs),
      content: SizedBox(
        width: double.maxFinite,
        child: Scrollbar(
          child: ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, i) {
              final event = events[events.length - 1 - i];

              return ListTile(
                title: Text(formatEventName(event.eventType.name)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(event.oldValue),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Icon(Icons.arrow_right_outlined),
                        ),
                        Text(event.newValue),
                      ],
                    ),
                    Text(formatter.format(event.dateTime.toLocal())),
                    if (event is MobileNetmanagerEvent) ...[
                      Text(
                        "SIM ${event.simSlot + 1} ${event.network.trim().isNotEmpty ? "(${event.network})" : "(${appLocalizations.unknown})"}",
                      ),
                    ],
                    if (i < events.length - 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 15.0),
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
          onPressed: () => _handleExport(context, appLocalizations),
          label: Text(appLocalizations.export),
          icon: const Icon(Icons.offline_share_outlined),
        ),
      ],
    );
  }

  Future<void> _handleExport(
    BuildContext context,
    AppLocalizations appLocalizations,
  ) async {
    await HapticService().triggerHaptic(HapticType.selection, context);

    final dir = await getTemporaryDirectory();
    final exportFolder = Directory("${dir.path}/exports");
    if (!exportFolder.existsSync()) {
      await exportFolder.create();
    }

    final file = File("${exportFolder.path}/event_list.txt");
    final content = events.join("\n");
    await file.writeAsString(content);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(appLocalizations.eventLogsSaved(file.path)),
          showCloseIcon: true,
        ),
      );
    }

    await platform.invokeMethod("share", {"path": file.path});
  }
}
