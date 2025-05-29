import 'package:netmanager/types/basic_cell_data.dart';

class CellData {
  final String cellIdentifierString;
  final String rawSignalString;
  final String processedSignalString;
  final String channelNumberString;
  final String stationIdentityString;
  final String areaCodeString;
  final String signalQualityString;
  final String signalNoiseString;
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
  final int timingAdvance;
  final int bandwidth;
  final int band;
  final BasicCellData basicCellData;

  final bool isRegistered;

  CellData({
    required this.cellIdentifierString,
    required this.rawSignalString,
    required this.processedSignalString,
    required this.channelNumberString,
    required this.stationIdentityString,
    required this.areaCodeString,
    required this.signalQualityString,
    required this.signalNoiseString,
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
    required this.timingAdvance,
    required this.bandwidth,
    required this.band,
    required this.basicCellData,

    required this.isRegistered,
  });

  factory CellData.fromJson(Map<String, dynamic> json) {
    return CellData(
      cellIdentifierString: json["cellIdentifierString"],
      rawSignalString: json["rawSignalString"],
      processedSignalString: json["processedSignalString"],
      channelNumberString: json["channelNumberString"],
      stationIdentityString: json["stationIdentityString"],
      areaCodeString: json["areaCodeString"],
      signalQualityString: json["signalQualityString"],
      signalNoiseString: json["signalNoiseString"],
      timingAdvanceString: json["timingAdvanceString"],
      bandwidthString: json["bandwidthString"],
      bandString: json["bandString"],

      cellIdentifier: json["cellIdentifier"],
      rawSignal: json["rawSignal"],
      processedSignal: json["processedSignal"],
      channelNumber: json["channelNumber"],
      stationIdentity: json["stationIdentity"],
      areaCode: json["areaCode"],
      signalQuality: json["signalQuality"],
      signalNoise: json["signalNoise"],
      timingAdvance: json["timingAdvance"],
      bandwidth: json["bandwidth"],
      band: json["band"],
      basicCellData:
          json["basicCellData"] is Map<String, dynamic>
              ? BasicCellData.fromJson(json["basicCellData"])
              : BasicCellData(band: -1, frequency: -1),
      isRegistered: json["isRegistered"],
    );
  }
}
