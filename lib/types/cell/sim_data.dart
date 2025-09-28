import 'package:netmanager/types/cell/basic_cell_data.dart';
import 'package:netmanager/types/cell/cell_data.dart';

class SIMData {
  final String operator;
  final String network;
  final int networkGen;
  final String homePlmn;
  final String networkPlmn;
  final CellData primaryCell;
  final double activeBw;
  final List<CellData> activeCells;
  final List<CellData> neighborCells;

  SIMData({
    required this.operator,
    required this.network,
    required this.networkGen,
    required this.homePlmn,
    required this.networkPlmn,
    required this.primaryCell,
    required this.activeBw,
    required this.activeCells,
    required this.neighborCells,
  });

  factory SIMData.fromJson(Map<String, dynamic> json) {
    return SIMData(
      operator: json["operator"],
      network: json["network"],
      networkGen: json["networkGen"],
      homePlmn: json["homePlmn"],
      networkPlmn: json["networkPlmn"],
      primaryCell: json["primaryCell"] is Map<String, dynamic>
          ? CellData.fromJson(json["primaryCell"])
          : _emptyCellData(),
      activeBw: (json["activeBw"] as num?)?.toDouble() ?? 0.0,
      activeCells: (json["activeCells"] as List<dynamic>? ?? [])
          .map((e) => CellData.fromJson(e))
          .toList(),
      neighborCells: (json["neighborCells"] as List<dynamic>? ?? [])
          .map((e) => CellData.fromJson(e))
          .toList(),
    );
  }
}

CellData _emptyCellData() => CellData(
  cellIdentifierString: "",
  nodeIdentifierString: "",
  rawSignalString: "",
  processedSignalString: "",
  channelNumberString: "",
  stationIdentityString: "",
  areaCodeString: "",
  signalQualityString: "",
  signalNoiseString: "",
  timingAdvanceString: "",
  bandwidthString: "",
  bandString: "",
  cellIdentifier: "-1",
  rawSignal: -1,
  processedSignal: -1,
  channelNumber: -1,
  stationIdentity: -1,
  areaCode: -1,
  signalQuality: -1,
  signalNoise: -1,
  timingAdvance: -1,
  bandwidth: -1,
  band: -1,
  basicCellData: BasicCellData(band: -1, frequency: -1),
  isRegistered: false,
);
