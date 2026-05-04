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
      operator: json["operator"],
      network: json["network"],
      date: DateTime.parse(json['date']),
      records: (json["records"] as List<dynamic>? ?? [])
          .map((e) => Record.fromJson(e))
          .toList(),
    );
  }
}
