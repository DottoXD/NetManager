import 'package:netmanager/types/events/event_types.dart';

class NetmanagerEvent {
  final EventTypes eventType;
  final String oldValue;
  final String newValue;
  final DateTime dateTime;

  NetmanagerEvent({
    required this.eventType,
    required this.oldValue,
    required this.newValue,
    required this.dateTime,
  });

  factory NetmanagerEvent.fromJson(Map<String, dynamic> json) {
    return NetmanagerEvent(
      eventType: eventTypeFromString(json['eventType']),
      oldValue: json['oldValue'],
      newValue: json['newValue'],
      dateTime: json['dateTime'],
    );
  }
}
