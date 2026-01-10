import 'package:flutter/material.dart';
import 'package:netmanager/components/utils/haptic_utils.dart';
import 'package:netmanager/types/events/event_types.dart';

Widget eventSelection(
  BuildContext context,
  List<EventTypes> selectedEvents,
  void Function(EventTypes) onEventsChanged,
) {
  final primaryColor = Theme.of(context).colorScheme.primary;

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 7.0),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: EventTypes.values.map((eventType) {
          final bool selected = selectedEvents.contains(eventType);

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: HapticTap(
              type: HapticType.SELECTION,
              child: FilterChip(
                label: Text(formatEventName(eventType.name)),
                selected: selected,
                checkmarkColor: primaryColor,
                shape: const StadiumBorder(),
                tooltip: eventType.toString(),
                side: selected
                    ? BorderSide(color: primaryColor)
                    : BorderSide.none,
                onSelected: (_) {
                  onEventsChanged(eventType);
                },
              ),
            ),
          );
        }).toList(),
      ),
    ),
  );
}
