import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:netmanager/components/utils/haptic_utils.dart';
import 'package:netmanager/types/events/event_types.dart';
import 'package:netmanager/types/events/mobile_netmanager_event.dart';
import 'package:netmanager/types/events/netmanager_event.dart';
import 'package:path_provider/path_provider.dart';

Widget eventLogDialog(
  BuildContext context,
  List<NetmanagerEvent> events,
  MethodChannel platform,
) {
  final formatter = DateFormat("dd/MM/yyyy HH:mm:ss");
  final outlineVariant = Theme.of(context).colorScheme.outlineVariant;

  if (events.isEmpty) throw "No events";

  return AlertDialog(
    title: Text("Event Logs"),
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
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Icon(Icons.arrow_right_rounded),
                      ),
                      Text(event.newValue),
                    ],
                  ),
                  Text(formatter.format(event.dateTime.toLocal())),
                  if (event is MobileNetmanagerEvent) ...[
                    Text(
                      "SIM ${event.simSlot + 1} ${event.network.trim().isNotEmpty ? "(${event.network})" : "(Unknown)"}",
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
      HapticTap(
        type: HapticType.SELECTION,
        child: TextButton.icon(
          onPressed: () async {
            final dir = await getExternalStorageDirectory();

            if (dir == null) {
              await platform.invokeMethod<bool>("showToast", {
                "message": "External storage is unavailable!",
              });
              return;
            }

            final file = File("${dir.path}/event_list.txt");
            final content = events.join("\n");
            await file.writeAsString(content);

            await platform.invokeMethod<bool>("showToast", {
              "message": "Event log saved at: ${file.path}",
            });
          },
          label: const Text("Export"),
          icon: const Icon(Icons.share),
        ),
      ),
      HapticTap(
        type: HapticType.SELECTION,
        child: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text("Close"),
        ),
      ),
    ],
  );
}
