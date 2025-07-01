import 'package:netmanager/types/events/event_types.dart';
import 'package:netmanager/types/events/netmanager_event.dart';

class MobileNetmanagerEvent extends NetmanagerEvent {
  final int simSlot;
  final String network;

  MobileNetmanagerEvent({
    required super.eventType,
    required super.oldValue,
    required super.newValue,
    required super.dateTime,
    required this.simSlot,
    required this.network,
  });

  factory MobileNetmanagerEvent.fromJson(Map<String, dynamic> json) {
    return MobileNetmanagerEvent(
      eventType: eventTypeFromString(json['eventType']),
      oldValue: json['oldValue'],
      newValue: json['newValue'],
      dateTime: DateTime.parse(json['dateTime']),
      simSlot: json['simSlot'],
      network: json['network'],
    );
  }
}
