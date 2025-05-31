import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:netmanager/types/cell_data.dart';
import 'package:netmanager/types/sim_data.dart';
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
  bool _isUpdating = false;

  double cardWidth = 185;
  double cardHeight = 75;

  final int minRssi = -113;
  final int maxRssi = -51;

  final int minRsrp = -140;
  final int maxRsrp = -43;

  String _debug = "";
  List<Widget> _mainData = <Widget>[];
  List<Widget> _activeData = <Widget>[];
  List<Widget> _neighborData = <Widget>[];

  late SIMData oldSimData;

  @override
  void initState() {
    super.initState();
    platform = widget.platform;
    sharedPreferences = widget.sharedPreferences;

    timer = Timer.periodic(
      Duration(seconds: sharedPreferences.getInt("updateInterval") ?? 3),
      (Timer t) {
        if (!_isUpdating) update();
      },
    );
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

      setState(() {
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
        "${simData.primaryCell.bandwidth}MHz",
        simData.primaryCell.bandString,
        simData.primaryCell.band.toString(),
      ];

      final List<Widget> validCards = [];

      for (int i = 0; i < elements.length - 1; i += 2) {
        final String label = elements[i];
        final String val = elements[i + 1];

        if (val.contains("-1") || val.contains("2147483647")) continue;

        validCards.add(
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            margin: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
            color: Theme.of(context).colorScheme.onSecondary,
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
                  margin: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                );

        mainData.add(
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [leftCard, rightCard],
          ),
        );
      }

      final List<Widget> activeData =
          simData.activeCells.map((cell) {
            return ListTile(
              title: Text(cell.bandString),
              subtitle: Text(
                "${cell.basicCellData.band} ${cell.bandwidth}MHz ${cell.processedSignal}dBm",
              ),
            );
          }).toList();

      final List<Widget> neighborData =
          simData.neighborCells.map((cell) {
            return ListTile(
              title: Text(cell.bandString),
              subtitle: Text(
                "${cell.basicCellData.band} ${cell.bandwidth}MHz ${cell.processedSignal}dBm",
              ),
            );
          }).toList();

      setState(() {
        _mainData = mainData;
        _activeData = activeData;
        _neighborData = neighborData;
        _progressIndicator = Container();
        _debug = jsonStr;
      });

      oldSimData = simData;
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
          Row(children: [Expanded(child: _progressIndicator)]),
          Container(
            margin: EdgeInsets.only(top: 10, left: 10, right: 10),
            child: Column(children: _mainData),
          ),
          Text("Active Cells"), //temporary
          Container(
            margin: EdgeInsets.only(top: 10, left: 10, right: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _activeData,
            ),
          ),
          Text("Neighbor Cells"), //temporary
          Container(
            margin: EdgeInsets.only(top: 10, left: 10, right: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _neighborData,
            ),
          ),
          Text(_debug),
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
          ((min(max(simData.primaryCell.rawSignal, minRsrp), maxRsrp) -
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
}
