import 'package:flutter/material.dart';
import 'package:netmanager/l10n/app_localizations.dart';

class SpeedtestHistoryResult {
  final int? id;
  final DateTime timestamp;
  final double download;
  final double upload;
  final int ping;
  final int jitter;
  final double packetLoss;
  final String carrier;
  final String plmn;
  final int networkGen;
  final String? serverName;
  final double? latitude;
  final double? longitude;
  final String? deviceModel;

  const SpeedtestHistoryResult({
    this.id,
    required this.timestamp,
    required this.download,
    required this.upload,
    required this.ping,
    required this.jitter,
    required this.packetLoss,
    required this.carrier,
    required this.plmn,
    required this.networkGen,
    this.serverName,
    this.latitude,
    this.longitude,
    this.deviceModel,
  });

  String getNetworkGenLabel() {
    return networkGen > 0 ? "${networkGen}G" : "N/A";
  }

  bool hasLocation() {
    return latitude != null && longitude != null;
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) "id": id,
      "timestamp": timestamp.millisecondsSinceEpoch,
      "downloadMbps": download,
      "uploadMbps": upload,
      "ping": ping,
      "jitter": jitter,
      "packetLoss": packetLoss,
      "carrier": carrier,
      "plmn": plmn,
      "networkGen": networkGen,
      "serverName": serverName,
      "latitude": latitude,
      "longitude": longitude,
      "deviceModel": deviceModel,
    };
  }

  factory SpeedtestHistoryResult.fromMap(Map<String, dynamic> map) {
    return SpeedtestHistoryResult(
      id: map["id"] as int?,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map["timestamp"] as int),
      download: (map["downloadMbps"] as num).toDouble(),
      upload: (map["uploadMbps"] as num).toDouble(),
      ping: map["ping"] as int,
      jitter: map["jitter"] as int,
      packetLoss: (map["packetLoss"] as num).toDouble(),
      carrier: map["carrier"] as String? ?? "",
      plmn: map["plmn"] as String? ?? "",
      networkGen: map["networkGen"] as int? ?? 0,
      serverName: map["serverName"] as String?,
      latitude: (map["latitude"] as num?)?.toDouble(),
      longitude: (map["longitude"] as num?)?.toDouble(),
      deviceModel: (map["deviceModel"] as String? ?? ""),
    );
  }

  static const List<String> csvHeader = [
    "timestamp",
    "download",
    "upload",
    "ping",
    "jitter",
    "packetLoss",
    "carrier",
    "plmn",
    "networkGen",
    "serverName",
    "latitude",
    "longitude",
    "deviceModel",
  ];

  List<String> toCsvFields() {
    return [
      timestamp.toIso8601String(),
      download.toString(),
      upload.toString(),
      ping.toString(),
      jitter.toString(),
      packetLoss.toString(),
      carrier,
      plmn,
      networkGen.toString(),
      serverName ?? "",
      latitude?.toString() ?? "",
      longitude?.toString() ?? "",
      deviceModel?.toString() ?? "",
    ];
  }

  factory SpeedtestHistoryResult.fromCsvFields(
    List<String> fields,
    BuildContext context,
  ) {
    final appLocalizations = AppLocalizations.of(context)!;

    if (fields.length < 10) {
      throw FormatException(appLocalizations.speedtestImportNoValidRows);
    }

    final DateTime? timestamp = DateTime.tryParse(fields[0]);
    final double? download = double.tryParse(fields[1]);
    final double? upload = double.tryParse(fields[2]);
    final int? ping = int.tryParse(fields[3]);
    final int? jitter = int.tryParse(fields[4]);
    final double? packetLoss = double.tryParse(fields[5]);
    final int? networkGen = int.tryParse(fields[8]);

    if (timestamp == null ||
        download == null ||
        upload == null ||
        ping == null ||
        jitter == null ||
        packetLoss == null ||
        networkGen == null) {
      throw FormatException(appLocalizations.speedtestImportNoValidRows);
    }

    return SpeedtestHistoryResult(
      timestamp: timestamp,
      download: download,
      upload: upload,
      ping: ping,
      jitter: jitter,
      packetLoss: packetLoss,
      carrier: fields[6],
      plmn: fields[7],
      networkGen: networkGen,
      serverName: fields[9].trim().isEmpty ? null : fields[9],
      latitude: fields.length > 10 && fields[10].trim().isNotEmpty
          ? double.tryParse(fields[10])
          : null,
      longitude: fields.length > 11 && fields[11].trim().isNotEmpty
          ? double.tryParse(fields[11])
          : null,
      deviceModel: fields.length > 12 && fields[12].trim().isEmpty
          ? null
          : fields[12],
    );
  }
}
