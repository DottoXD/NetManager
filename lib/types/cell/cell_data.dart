import 'package:netmanager/types/cell/basic_cell_data.dart';

class CellData {
  final String cellIdentifierString;
  final String nodeIdentifierString;
  final String rawSignalString;
  final String processedSignalString;
  final String channelNumberString;
  final String stationIdentityString;
  final String areaCodeString;
  final String signalQualityString;
  final String signalNoiseString;
  final String channelQualityString;
  final String timingAdvanceString;
  final String bandwidthString;
  final String bandString;

  final String cellIdentifier;

  final int rawSignal;
  final int processedSignal;
  final int channelNumber;
  final int stationIdentity;
  final int areaCode;
  final int signalQuality;
  final int signalNoise;
  final int channelQuality;
  final int timingAdvance;
  final int bandwidth;
  final int band;
  final BasicCellData basicCellData;

  final bool isRegistered;

  CellData({
    required this.cellIdentifierString,
    required this.nodeIdentifierString,
    required this.rawSignalString,
    required this.processedSignalString,
    required this.channelNumberString,
    required this.stationIdentityString,
    required this.areaCodeString,
    required this.signalQualityString,
    required this.signalNoiseString,
    required this.channelQualityString,
    required this.timingAdvanceString,
    required this.bandwidthString,
    required this.bandString,

    required this.cellIdentifier,
    required this.rawSignal,
    required this.processedSignal,
    required this.channelNumber,
    required this.stationIdentity,
    required this.areaCode,
    required this.signalQuality,
    required this.signalNoise,
    required this.channelQuality,
    required this.timingAdvance,
    required this.bandwidth,
    required this.band,
    required this.basicCellData,

    required this.isRegistered,
  });

  factory CellData.fromJson(Map<String, dynamic> json) {
    return CellData(
      cellIdentifierString: json["cellIdentifierString"] ?? "",
      nodeIdentifierString: json["nodeIdentifierString"] ?? "",
      rawSignalString: json["rawSignalString"] ?? "",
      processedSignalString: json["processedSignalString"] ?? "",
      channelNumberString: json["channelNumberString"] ?? "",
      stationIdentityString: json["stationIdentityString"] ?? "",
      areaCodeString: json["areaCodeString"] ?? "",
      signalQualityString: json["signalQualityString"] ?? "",
      signalNoiseString: json["signalNoiseString"] ?? "",
      channelQualityString: json["channelQualityString"] ?? "",
      timingAdvanceString: json["timingAdvanceString"] ?? "",
      bandwidthString: json["bandwidthString"] ?? "",
      bandString: json["bandString"] ?? "",

      cellIdentifier: json["cellIdentifier"]?.toString() ?? "-1",
      rawSignal: json["rawSignal"] ?? -1,
      processedSignal: json["processedSignal"] ?? -1,
      channelNumber: json["channelNumber"] ?? -1,
      stationIdentity: json["stationIdentity"] ?? -1,
      areaCode: json["areaCode"] ?? -1,
      signalQuality: json["signalQuality"] ?? -1,
      signalNoise: json["signalNoise"] ?? -1,
      channelQuality: json["channelQuality"] ?? -1,
      timingAdvance: json["timingAdvance"] ?? -1,
      bandwidth: json["bandwidth"] ?? -1,
      band: json["band"] ?? -1,
      basicCellData: json["basicCellData"] is Map<String, dynamic>
          ? BasicCellData.fromJson(json["basicCellData"])
          : BasicCellData(band: -1, frequency: -1),
      isRegistered: json["isRegistered"] ?? false,
    );
  }
}
