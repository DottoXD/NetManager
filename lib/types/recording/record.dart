import 'package:netmanager/types/cell/sim_data.dart';

class Record {
  final bool usable;
  final DateTime dateTime;
  final double lat;
  final double lon;
  final SIMData? simData;

  final int? _legacySignal;
  final int? _legacyGen;

  Record({
    required this.usable,
    required this.dateTime,
    required this.lat,
    required this.lon,
    this.simData,
    this._legacySignal,
    this._legacyGen,
  });

  int get processedSignal =>
      simData?.primaryCell.processedSignal ?? _legacySignal ?? -1;
  int get networkGen => simData?.networkGen ?? _legacyGen ?? -1;

  factory Record.fromJson(Map<String, dynamic> json) {
    return Record(
      usable: json["usable"] ?? true,
      dateTime: DateTime.tryParse(json["dateTime"] ?? "") ?? DateTime.now(),
      lat: (json["lat"] as num?)?.toDouble() ?? 0.0,
      lon: (json["lon"] as num?)?.toDouble() ?? 0.0,
      simData: json["simData"] != null
          ? SIMData.fromJson(json["simData"])
          : null,
      legacySignal: json["processedSignal"],
      legacyGen: json["networkGen"],
    );
  }
}
