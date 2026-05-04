class Record {
  final int networkGen;
  final String processedSignal;
  final bool usable;
  final DateTime dateTime;
  final double lat;
  final double lon;

  Record({
    required this.networkGen,
    required this.processedSignal,
    required this.usable,
    required this.dateTime,
    required this.lat,
    required this.lon,
  });

  factory Record.fromJson(Map<String, dynamic> json) {
    return Record(
      networkGen: json['networkGen'],
      processedSignal: json['processedSignal'],
      usable: json['usable'] ?? true,
      dateTime: DateTime.parse(json['dateTime']),
      lat: json['lat'],
      lon: json['lon'],
    );
  }
}
