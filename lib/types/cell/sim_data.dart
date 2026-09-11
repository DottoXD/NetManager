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
  final List<CellData> likelyCells;
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
    required this.likelyCells,
    required this.neighborCells,
  });

  SIMData copyWith({
    String? operator,
    String? network,
    int? networkGen,
    String? homePlmn,
    String? networkPlmn,
    CellData? primaryCell,
    double? activeBw,
    List<CellData>? activeCells,
    List<CellData>? likelyCells,
    List<CellData>? neighborCells,
  }) {
    return SIMData(
      operator: operator ?? this.operator,
      network: network ?? this.network,
      networkGen: networkGen ?? this.networkGen,
      homePlmn: homePlmn ?? this.homePlmn,
      networkPlmn: networkPlmn ?? this.networkPlmn,
      primaryCell: primaryCell ?? this.primaryCell,
      activeBw: activeBw ?? this.activeBw,
      activeCells: activeCells ?? this.activeCells,
      likelyCells: likelyCells ?? this.likelyCells,
      neighborCells: neighborCells ?? this.neighborCells,
    );
  }

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
      likelyCells: (json["likelyCells"] as List<dynamic>? ?? [])
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
  channelQualityString: "",
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
  channelQuality: -1,
  timingAdvance: -1,
  bandwidth: -1,
  band: -1,
  basicCellData: BasicCellData(band: -1, frequency: -1),
  isRegistered: false,
);
