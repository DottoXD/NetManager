import 'package:netmanager/types/events/netmanager_event.dart';
import 'package:netmanager/types/events/mobile_netmanager_event.dart';
import 'package:netmanager/types/recording/record.dart';
import 'package:netmanager/types/speedtest/history_result.dart';

List<NetmanagerEvent> getEventsForRecord({
  required Record currentRecord,
  required List<Record> sortedRecords,
  required List<NetmanagerEvent> events,
}) {
  if (sortedRecords.isEmpty || events.isEmpty) return [];

  final orderedRecords = List<Record>.from(sortedRecords)
    ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

  final currentTime = currentRecord.dateTime.toUtc();
  final index = orderedRecords.indexWhere(
    (r) => r.dateTime.toUtc().isAtSameMomentAs(currentTime),
  );

  if (index <= 0) return [];

  final DateTime startTime = orderedRecords[index - 1].dateTime.toUtc();

  final bool isLastRecord = index == orderedRecords.length - 1;
  final DateTime endTime = isLastRecord
      ? currentTime.add(const Duration(minutes: 5))
      : currentTime;

  return events.where((event) {
    final eventUtc = event.dateTime.toUtc();
    final isInWindow =
        eventUtc.isAfter(startTime) &&
        (eventUtc.isBefore(endTime) || eventUtc.isAtSameMomentAs(endTime));

    if (!isInWindow) return false;

    if (event is MobileNetmanagerEvent) {
      final sim = currentRecord.simData;
      if (sim == null) return true;

      final eventNetworkName = event.network.trim().toLowerCase();
      if (eventNetworkName.isEmpty || eventNetworkName == "Unknown") {
        return true;
      }

      final simNet = sim.network.trim().toLowerCase();
      final simOp = sim.operator.trim().toLowerCase();

      return simNet.contains(eventNetworkName) ||
          simOp.contains(eventNetworkName) ||
          eventNetworkName.contains(simNet);
    }

    return true;
  }).toList();
}

List<SpeedtestHistoryResult> getSpeedtestsForRecord({
  required Record currentRecord,
  required List<Record> sortedRecords,
  required List<SpeedtestHistoryResult> speedtests,
}) {
  if (sortedRecords.isEmpty || speedtests.isEmpty) return [];

  final orderedRecords = List<Record>.from(sortedRecords)
    ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

  final currentTime = currentRecord.dateTime.toUtc();
  final index = orderedRecords.indexWhere(
    (r) => r.dateTime.toUtc().isAtSameMomentAs(currentTime),
  );

  if (index <= 0) return [];

  final DateTime startTime = orderedRecords[index - 1].dateTime.toUtc();

  final bool isLastRecord = index == orderedRecords.length - 1;
  final DateTime endTime = isLastRecord
      ? currentTime.add(const Duration(minutes: 5))
      : currentTime;

  return speedtests.where((st) {
    final speedtestTime = st.timestamp.toUtc();
    return speedtestTime.isAfter(startTime) &&
        (speedtestTime.isBefore(endTime) ||
            speedtestTime.isAtSameMomentAs(endTime));
  }).toList();
}
