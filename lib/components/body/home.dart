import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

class HomeBody extends StatefulWidget {
  const HomeBody(this.platform, this.sharedPreferences, {super.key});
  final MethodChannel platform;
  final SharedPreferences sharedPreferences;

  @override
  State<HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> {
  late MethodChannel platform;
  late Timer timer;
  late SharedPreferences sharedPreferences;
  Widget _progressIndicator = LinearProgressIndicator();

  double cardWidth = 185;
  double cardHeight = 75;

  String _debug = "";
  final List<Widget> _mainData = <Widget>[];
  final List<Widget> _neighborData = <Widget>[];

  @override
  void initState() {
    super.initState();
    platform = widget.platform;
    sharedPreferences = widget.sharedPreferences;

    timer = Timer.periodic(
      Duration(seconds: sharedPreferences.getInt("updateInterval") ?? 3),
      (Timer t) => update(),
    );
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  void update() {
    try {
      () async {
        final String jsonStr = await platform.invokeMethod("getNetworkData");
        setState(() {
          _debug = jsonStr;
        });
        final Map<String, dynamic> map = json.decode(jsonStr);
        final SIMData simData;

        try {
          simData = SIMData.fromJson(map);
        } catch (e) {
          setState(() {
            _debug = "$jsonStr $e";
          });

          return;
        }

        _mainData.clear();
        _mainData.add(
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                margin: EdgeInsets.only(bottom: 10),
                color: Theme.of(context).colorScheme.onSecondary,
                child: Container(
                  width: cardWidth * 2 + 10,
                  height: (cardHeight * 2) - 20,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        simData.primaryCell.cellIdentifierString,
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 3),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(Icons.network_cell_sharp, size: 50),
                          Text(
                            simData.primaryCell.cellIdentifier.toString(),
                            style: TextStyle(fontSize: 24),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );

        List<String> elements = [
          simData.primaryCell.rawSignalString,
          "${simData.primaryCell.rawSignal}dBm",
          simData.primaryCell.processedSignalString,
          "${simData.primaryCell.processedSignal}dBm",
          simData.primaryCell.signalQualityString,
          "${simData.primaryCell.signalQuality}dBm",
          simData.primaryCell.signalNoiseString,
          "${simData.primaryCell.signalNoise}dBm",
          simData.primaryCell.channelNumberString,
          simData.primaryCell.channelNumber.toString(),
          simData.primaryCell.stationIdentityString,
          simData.primaryCell.stationIdentity.toString(),
          simData.primaryCell.areaCodeString,
          simData.primaryCell.areaCode.toString(),
          simData.primaryCell.timingAdvanceString,
          simData.primaryCell.timingAdvance.toString(),
          simData.primaryCell.bandwidthString,
          "${simData.primaryCell.bandwidth}MHz",
          simData.primaryCell.bandString,
          simData.primaryCell.band.toString(),
        ];

        for (int i = 0; i < elements.length - 1; i += 2) {
          if (elements[i + 1].contains("-1")) {
            if (i + 2 > elements.length) {
              //possibly fix? got to test
              break;
            } else {
              i += 2;
            }
          }

          Widget leftElement = Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            margin: EdgeInsets.only(bottom: 10, right: 5),
            color: Theme.of(context).colorScheme.onSecondary,
            child: Container(
              width: cardWidth,
              height: cardHeight,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ListTile(
                    title: Text(elements[i]),
                    subtitle: Text(elements[i + 1]),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[getTrailingIcon(simData, elements[i])],
                    ),
                  ),
                ],
              ),
            ),
          );

          Widget rightElement;

          if (i + 2 > elements.length) {
            rightElement = Container(
              width: cardWidth,
              height: cardHeight,
              margin: EdgeInsets.only(bottom: 10, right: 5),
            );
          } else {
            rightElement = Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              margin: EdgeInsets.only(bottom: 10, left: 5),
              color: Theme.of(context).colorScheme.onSecondary,
              child: Container(
                width: cardWidth,
                height: cardHeight,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ListTile(
                      title: Text(elements[i + 2]),
                      subtitle: Text(elements[i + 3]),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          getTrailingIcon(simData, elements[i + 2]),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );

            i += 2;
          }

          _mainData.add(
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [leftElement, rightElement],
            ),
          );
        }

        _neighborData.clear(); //experimental
        for (CellData neighborCell in simData.neighborCells) {
          _neighborData.add(
            ListTile(
              title: Text(neighborCell.bandString),
              subtitle: Text("${neighborCell.band}"),
            ),
          );
        }

        setState(() {
          _debug = jsonStr;

          _mainData;
          _neighborData;
          _progressIndicator = Container();
        });
      }();
    } on PlatformException catch (err) {
      _debug = err.toString();

      setState(() {
        _debug;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Column(
        children: <Widget>[
          Text(_debug),
          Row(children: [Expanded(child: _progressIndicator)]),
          Container(
            margin: EdgeInsets.only(top: 10, left: 10, right: 10),
            child: Column(children: _mainData),
          ),
          Container(
            margin: EdgeInsets.only(top: 10, left: 10, right: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _neighborData,
            ),
          ),
        ],
      ),
    );
  }

  Icon getTrailingIcon(SIMData simData, String val) {
    if (val == simData.primaryCell.rawSignalString) {
      //RSSI
      return Icon(
        Icons.signal_cellular_alt,
      ); //might make this based on the value
    } else if (val == simData.primaryCell.processedSignalString) {
      //RSRP
      return Icon(
        Icons.signal_cellular_0_bar,
      ); //might make this based on the value
    } else if (val == simData.primaryCell.signalQualityString) {
      //SNR
      return Icon(Icons.settings_input_antenna_outlined);
    } else if (val == simData.primaryCell.signalNoiseString) {
      //RSRQ
      return Icon(Icons.spatial_tracking);
    } else if (val == simData.primaryCell.channelNumberString) {
      //EARFCN
      return Icon(Icons.wifi_channel);
    } else if (val == simData.primaryCell.stationIdentityString) {
      //PCI
      return Icon(Icons.perm_identity);
    } else if (val == simData.primaryCell.areaCodeString) {
      //TAC
      return Icon(Icons.landscape);
    } else if (val == simData.primaryCell.timingAdvanceString) {
      //TA
      return Icon(Icons.shortcut);
    } else if (val == simData.primaryCell.bandwidthString) {
      //BW
      return Icon(Icons.swap_horiz_rounded);
    }

    return Icon(Icons.question_mark); //Unknown icon
  }
}

class SIMData {
  final String operator;
  final String network;
  final int networkGen;
  final String mccMnc;
  final CellData primaryCell;
  final double activeBw;
  final List<CellData> activeCells;
  final List<CellData> neighborCells;

  SIMData({
    required this.operator,
    required this.network,
    required this.networkGen,
    required this.mccMnc,
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
      mccMnc: json["mccMnc"],
      primaryCell:
          json["primaryCell"] is Map<String, dynamic>
              ? CellData.fromJson(json["primaryCell"])
              : _emptyCellData(),
      activeBw: (json["activeBw"] as num?)?.toDouble() ?? 0.0,
      activeCells:
          (json["activeCells"] as List<dynamic>? ?? [])
              .map((e) => CellData.fromJson(e))
              .toList(),
      neighborCells:
          (json["neighborCells"] as List<dynamic>? ?? [])
              .map((e) => CellData.fromJson(e))
              .toList(),
    );
  }
}

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

  final String rawSignal;
  final String processedSignal;
  final int channelNumber;
  final int stationIdentity;
  final String areaCode;
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

class BasicCellData {
  final int band;
  final int frequency;

  BasicCellData({required this.band, required this.frequency});

  factory BasicCellData.fromJson(Map<String, dynamic> json) {
    return BasicCellData(band: json["band"], frequency: json["frequency"]);
  }
}

CellData _emptyCellData() => CellData(
  cellIdentifierString: "",
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
  rawSignal: "-1",
  processedSignal: "-1",
  channelNumber: -1,
  stationIdentity: -1,
  areaCode: "-1",
  signalQuality: -1,
  signalNoise: -1,
  timingAdvance: -1,
  bandwidth: -1,
  band: -1,
  basicCellData: BasicCellData(band: -1, frequency: -1),
  isRegistered: false,
);
