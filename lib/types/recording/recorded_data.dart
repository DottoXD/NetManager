import 'package:netmanager/types/recording/record.dart';

class RecordedData {
  final String operator;
  final String network;
  final DateTime date;
  final List<Record> records;

  RecordedData({
    required this.operator,
    required this.network,
    required this.date,
    required this.records,
  });

  factory RecordedData.fromJson(Map<String, dynamic> json) {
    return RecordedData(
      operator: json["operator"] ?? "Unknown",
      network: json["network"] ?? "Unknown",
      date: DateTime.tryParse(json["date"] ?? "") ?? DateTime.now(),
      records: (json["records"] as List<dynamic>? ?? [])
          .map((e) => Record.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
