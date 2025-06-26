import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:netmanager/types/cell_data.dart';
import 'package:netmanager/types/sim_data.dart';
import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

class HomeBody extends StatefulWidget {
  const HomeBody(
    this.platform,
    this.sharedPreferences,
    this.homeLoaded, {
    super.key,
  });
  final MethodChannel platform;
  final SharedPreferences sharedPreferences;
  final bool homeLoaded;

  @override
  State<HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> {
  late MethodChannel platform;
  late Timer timer;
  late SharedPreferences sharedPreferences;
  late bool homeLoaded;
  Widget _progressIndicator = LinearProgressIndicator();
  bool _isUpdating = false;

  double cardWidth = 185;
  double cardHeight = 75;

  final int minRssi = -113;
  final int maxRssi = -51;

  final int minRsrp = -140;
  final int maxRsrp = -43;

  String _debug = "";
  String plmn = "";

  List<Widget> _mainData = <Widget>[];
  List<Widget> _activeData = <Widget>[];
  List<Widget> _neighborData = <Widget>[];

  @override
  void initState() {
    super.initState();
    platform = widget.platform;
    sharedPreferences = widget.sharedPreferences;
    homeLoaded = widget.homeLoaded;

    platform.setMethodCallHandler((call) {
      if (call.method == "restartTimer") {
        restartTimer();
        return Future.value();
      }

      return Future.value();
    });

    startTimer();
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  Future<void> update() async {
    if (_isUpdating) return;
    _isUpdating = true;

    try {
      final String jsonStr = await platform.invokeMethod("getNetworkData");
      plmn = (await platform.invokeMethod<String>("getPlmn"))!;

      setState(() {
        _progressIndicator = LinearProgressIndicator();
        _debug = jsonStr;
      });

      final Map<String, dynamic> map = json.decode(jsonStr);
      late final SIMData simData;

      try {
        simData = SIMData.fromJson(map);
      } catch (e) {
        setState(() {
          _debug = "$jsonStr\nError: $e";
        });
        return;
      }

      final List<Widget> mainData = [];

      mainData.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 5.0, vertical: 2.5),
                child: Tooltip(
                  message:
                      "${simData.primaryCell.cellIdentifierString} (${simData.primaryCell.cellIdentifier})",
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(17.5),
                        ),
                        margin: EdgeInsets.only(bottom: 5),
                        color: Theme.of(context).colorScheme.primaryContainer,
                        child: Container(
                          width: cardWidth * 2 + 10,
                          height: (cardHeight * 2) - 20,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                simData.primaryCell.cellIdentifierString,
                                style: TextStyle(fontSize: 16),
                              ),
                              SizedBox(height: 3),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Icon(Icons.cell_tower_rounded, size: 40),
                                  SizedBox(width: 6),
                                  Text(
                                    simData.primaryCell.cellIdentifier
                                        .toString(),
                                    style: TextStyle(fontSize: 24),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

      final List<String> elements = [
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
        "${simData.activeBw}MHz",
        simData.primaryCell.bandString,
        simData.primaryCell.band.toString(),
      ];

      final List<Widget> validCards = [];

      for (int i = 0; i < elements.length - 1; i += 2) {
        final String label = elements[i];
        final String val = elements[i + 1];

        if (!isValidString(val)) {
          continue;
        }

        validCards.add(
          Tooltip(
            message: label,
            child: InkWell(
              child: Material(
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17.5),
                  ),
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Container(
                    width: cardWidth,
                    height: cardHeight,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        ListTile(
                          title: Text(label),
                          subtitle: Text(val),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[getTrailingIcon(simData, label)],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }

      for (int i = 0; i < validCards.length; i += 2) {
        final Widget leftCard = validCards[i];
        final Widget rightCard =
            (i + 1 < validCards.length)
                ? validCards[i + 1]
                : Container(
                  width: cardWidth,
                  height: cardHeight,
                  margin: EdgeInsets.symmetric(vertical: 5),
                );

        mainData.add(
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2.5, vertical: 2.5),
                  child: leftCard,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2.5, vertical: 2.5),
                  child: rightCard,
                ),
              ),
            ],
          ),
        );
      }

      int? eNodeB = int.tryParse(simData.primaryCell.cellIdentifier);

      final List<Widget> activeData =
          simData.activeCells.map((cell) {
            int i = simData.activeCells.indexOf(cell);

            String cellContent = createCellContent(cell).replaceAll(
              "%enodeb%",
              (eNodeB != null
                  ? "Likely ${(eNodeB / 256).floor()}"
                  : "Unknown cell"),
            );

            List<IconData> icons = [
              Icons.signal_cellular_connected_no_internet_0_bar_rounded,
              Icons.signal_cellular_connected_no_internet_4_bar_rounded,
              Icons.signal_cellular_0_bar_rounded,
              Icons.signal_cellular_4_bar_rounded,
              Icons.question_mark,
            ];

            int index = 4;

            if (isValidInt(cell.processedSignal)) {
              index =
                  ((min(
                                max(
                                  simData.primaryCell.processedSignal,
                                  minRsrp,
                                ),
                                maxRsrp,
                              ) -
                              minRsrp) /
                          ((maxRsrp - minRsrp) / 2))
                      .floor();
            } else if (isValidInt(cell.rawSignal)) {
              index =
                  ((min(max(simData.primaryCell.rawSignal, minRssi), maxRssi) -
                              minRssi) /
                          ((maxRssi - minRssi) / 2))
                      .floor();
            }

            if (index != 4 && cell.isRegistered) index += 2;

            return Column(
              children: [
                ListTile(
                  title: Text(
                    "${cell.channelNumberString == "ARFCN" ? "N" : "B"}${cell.basicCellData.band} (${cell.basicCellData.frequency}MHz)",
                  ),
                  subtitle: Text(cellContent),
                  trailing: Icon(icons[index]),
                ),
                if (i != 0 && i != simData.activeCells.length - 1)
                  Divider(height: 0),
              ],
            );
          }).toList();

      final List<Widget> neighborData =
          simData.neighborCells.map((cell) {
            int i = simData.neighborCells.indexOf(cell);

            String cellContent = createCellContent(cell).replaceAll(
              "%enodeb%",
              (eNodeB != null
                  ? "Likely ${(eNodeB / 256).floor()}"
                  : "Unknown cell"),
            );

            return Column(
              children: [
                ListTile(
                  title: Text(
                    "${cell.channelNumberString == "ARFCN" ? "N" : "B"}${cell.basicCellData.band} (${cell.basicCellData.frequency}MHz)",
                  ),
                  subtitle: Text(cellContent),
                ),
                if (i != 0 && i != simData.neighborCells.length - 1)
                  Divider(height: 0),
              ],
            );
          }).toList();

      setState(() {
        _mainData = mainData;
        _activeData = activeData;
        _neighborData = neighborData;
        _progressIndicator = Container();
        _debug = jsonStr;
      });
    } on PlatformException catch (err) {
      setState(() {
        _debug = "PlatformException: ${err.toString()}";
      });
    } finally {
      _isUpdating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Column(
        children: <Widget>[
          if (!homeLoaded)
            Container(
              height: MediaQuery.of(context).size.height,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                ],
              ),
            )
          else if (homeLoaded && plmn.isEmpty)
            Container(
              height: MediaQuery.of(context).size.height,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.airplanemode_on,
                    size: 80,
                    //color: Theme.of(context).colorScheme.primaryContainer,
                  ),
                  SizedBox(height: 20),
                  Text("Airplane mode on", style: TextStyle(fontSize: 22)),
                ],
              ),
            )
          else
            Column(
              children: [
                Row(children: [Expanded(child: _progressIndicator)]),
                Container(
                  margin: EdgeInsets.only(
                    top: 10,
                    left: 10,
                    right: 10,
                    bottom: 10,
                  ),
                  child: Column(children: _mainData),
                ),
                if (_activeData.isNotEmpty) ...[
                  Text("Active Cells"),
                  Container(
                    margin: EdgeInsets.only(
                      top: 10,
                      left: 10,
                      right: 10,
                      bottom: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: _activeData,
                    ),
                  ),
                ],
                if (_neighborData.isNotEmpty) ...[
                  Text("Neighbor Cells"),
                  Container(
                    margin: EdgeInsets.only(
                      top: 10,
                      left: 10,
                      right: 10,
                      bottom: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: _neighborData,
                    ),
                  ),
                ],
                if (_debug.isNotEmpty && _debug != "null")
                  Container(
                    margin: EdgeInsets.only(
                      top: 10,
                      left: 20,
                      right: 20,
                      bottom: 20,
                    ),
                    child: Text("Debug: $_debug"),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Icon getTrailingIcon(SIMData simData, String val) {
    if (val == simData.primaryCell.rawSignalString) {
      //RSSI

      List<IconData> icons = [
        Icons.signal_cellular_alt_1_bar,
        Icons.signal_cellular_alt_2_bar,
        Icons.signal_cellular_alt,
      ];

      int index =
          ((min(max(simData.primaryCell.rawSignal, minRssi), maxRssi) -
                      minRssi) /
                  ((maxRssi - minRssi) / 3))
              .floor();

      return Icon(icons[min(index, 2)]);
    } else if (val == simData.primaryCell.processedSignalString) {
      //RSRP

      List<IconData> icons = [
        Icons.signal_cellular_connected_no_internet_0_bar,
        Icons.signal_cellular_0_bar,
        Icons.signal_cellular_4_bar,
      ];

      int index =
          ((min(max(simData.primaryCell.processedSignal, minRsrp), maxRsrp) -
                      minRsrp) /
                  ((maxRsrp - minRsrp) / 3))
              .floor();

      return Icon(icons[min(index, 2)]);
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

  String createCellContent(CellData cell) {
    String cellContent = "";

    int? cellId = int.tryParse(cell.cellIdentifier);
    if (cellId != null && isValidString(cell.cellIdentifier)) {
      cellContent += "${(cellId / 256).floor()}/${cellId % 256}, ";
    } else if (cell.isRegistered) {
      cellContent += "%enodeb%, ";
    } else {
      cellContent += "Unknown cell, ";
    }

    if (isValidInt(cell.bandwidth)) {
      cellContent += "${cell.bandwidthString}: ${cell.bandwidth}MHz";
    } else {
      cellContent += "Unknown bandwidth";
    }

    cellContent += ".\n";

    if (isValidInt(cell.areaCode)) {
      cellContent += "${cell.areaCodeString}: ${cell.areaCode}, ";
    }

    if (isValidInt(cell.channelNumber)) {
      cellContent += "${cell.channelNumberString}: ${cell.channelNumber}, ";
    }

    if (isValidInt(cell.stationIdentity)) {
      cellContent += "${cell.stationIdentityString}: ${cell.stationIdentity}, ";
    }

    if (isValidInt(cell.timingAdvance)) {
      cellContent += "${cell.timingAdvanceString}: ${cell.timingAdvance}";
    }

    if (cellContent.endsWith(", ")) {
      cellContent = cellContent.substring(0, cellContent.length - 2);
    }

    cellContent += ".\n";
    cellContent.replaceAll("\n.\n", "\n");

    if (isValidInt(cell.processedSignal)) {
      cellContent +=
          "${cell.processedSignalString} ${cell.processedSignal}dBm, ";
    } else if (isValidInt(cell.rawSignal)) {
      cellContent += "${cell.rawSignalString} ${cell.rawSignal}dBm, ";
    }

    if (isValidInt(cell.signalQuality)) {
      cellContent += "${cell.signalQualityString} ${cell.signalQuality}dBm, ";
    }

    if (isValidInt(cell.signalNoise)) {
      cellContent += "${cell.signalNoiseString} ${cell.signalNoise}dBm";
    }

    if (cellContent.endsWith(", ")) {
      cellContent = "${cellContent.substring(0, cellContent.length - 2)}.";
    } else {
      cellContent += ".";
    }

    if (cellContent.isEmpty) cellContent = "No info for this cell.";

    return cellContent;
  }

  bool isValidInt(int val) {
    return !(val == -1 || val == 2147483647);
  }

  bool isValidString(String val) {
    return !(val.contains("-1") ||
        val.contains("2147483647") ||
        val.contains("null"));
  }

  void startTimer() {
    update();

    timer = Timer.periodic(
      Duration(seconds: sharedPreferences.getInt("updateInterval") ?? 3),
      (Timer t) {
        update();
        homeLoaded = true;
      },
    );
  }

  void restartTimer() {
    timer.cancel();
    startTimer();
  }
}
