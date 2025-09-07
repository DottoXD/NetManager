import 'package:flutter/material.dart';
import 'package:netmanager/types/events/mobile_netmanager_event.dart';
import 'package:netmanager/types/events/netmanager_event.dart';

Widget eventLogDialog(BuildContext context, List<NetmanagerEvent> events) {
  return AlertDialog(
    title: Text("Event Logs"),
    content: SizedBox(
      width: double.maxFinite,
      child: Scrollbar(
        child: ListView.builder(
          itemCount: events.length,
          itemBuilder: (context, i) {
            final event = events[i];

            DateTime dt = event.dateTime.toLocal();

            return ListTile(
              title: Text(formatEventName(event.eventType.name)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(event.oldValue),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5),
                        child: Icon(Icons.arrow_right_rounded),
                      ),
                      Text(event.newValue),
                    ],
                  ),
                  Text(
                    "${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute}:${dt.second}",
                  ),
                  if (event is MobileNetmanagerEvent) ...[
                    Text("SIM ${event.simSlot + 1} (${event.network})"),
                  ],
                  if (i < events.length - 1)
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

String formatEventName(String name) {
  String finalName = name
      .replaceFirst("MOBILE_", "")
      .replaceAll("_", " ")
      .toUpperCase();

  return finalName;
}
