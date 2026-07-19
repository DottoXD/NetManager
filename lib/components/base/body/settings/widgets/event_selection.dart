import 'package:flutter/material.dart';
import 'package:netmanager/utils/haptic_service.dart';
import 'package:netmanager/types/events/event_types.dart';

class EventSelection extends StatelessWidget {
  const EventSelection({
    super.key,
    required this.selectedEvents,
    required this.onEventsChanged,
  });

  final List<EventTypes> selectedEvents;
  final void Function(EventTypes) onEventsChanged;

  @override
  Widget build(BuildContext context) {
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
              child: FilterChip(
                label: Text(formatEventName(eventType.name)),
                selected: selected,
                checkmarkColor: primaryColor,
                shape: const StadiumBorder(),
                tooltip: eventType.toString(),
                side: selected
                    ? BorderSide(color: primaryColor)
                    : BorderSide.none,
                onSelected: (_) async {
                  await HapticService().triggerHaptic(
                    HapticType.selection,
                    context,
                  );

                  onEventsChanged(eventType);
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
