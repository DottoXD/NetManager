import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:netmanager/types/cell/cell_data.dart';
import 'package:netmanager/types/cell/sim_data.dart';
import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

class HomeBody extends StatefulWidget {
  const HomeBody(
    this.platform,
    this.sharedPreferences,
    this.homeLoadedNotifier,
    this.platformSignalNotifier,
    this.debugNotifier, {
    super.key,
    this.onUpdateButtonPressed,
  });
  final MethodChannel platform;
  final SharedPreferences sharedPreferences;
  final ValueNotifier<bool> homeLoadedNotifier;
  final ValueNotifier<int> platformSignalNotifier;
  final ValueNotifier<bool> debugNotifier;

  final ValueSetter<VoidCallback>? onUpdateButtonPressed;

  @override
  State<HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> {
  late MethodChannel platform;
  late Timer timer;
  late SharedPreferences sharedPreferences;
  late ValueNotifier<bool> homeLoadedNotifier;
  late ValueNotifier<int> platformSignalNotifier;
  late ValueNotifier<bool> debugNotifier;

  Widget _progressIndicator = LinearProgressIndicator();
  bool _isUpdating = false;

  final double cardWidth = 185;
  final double cardHeight = 75;

  final int minRssi = -113;
  final int maxRssi = -51;

  final int minRsrp = -140;
  final int maxRsrp = -43;

  String _debug = "";
  String plmn = "";
  bool pageLoaded = false;

  bool altCellView = false;

  List<Widget> _mainData = <Widget>[];
  List<Widget> _activeData = <Widget>[];
  List<Widget> _neighborData = <Widget>[];

  @override
  void initState() {
    super.initState();
    platform = widget.platform;
    sharedPreferences = widget.sharedPreferences;
    homeLoadedNotifier = widget.homeLoadedNotifier;
    debugNotifier = widget.debugNotifier;

    widget.onUpdateButtonPressed?.call(update);

    startTimer();

    widget.platformSignalNotifier.addListener(() {
      restartTimer();
    });
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
      });

      //jsonStr is null at start - todo fix.
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

      int factor = conversionFactor(simData.primaryCell);

      mainData.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 7.5, vertical: 7.5),
                child: Tooltip(
                  message:
                      (simData.primaryCell.cellIdentifier.contains("-1") ||
                          simData.primaryCell.cellIdentifier == "0"
                      ? "Unknown"
                      : (altCellView
                            ? "${simData.primaryCell.cellIdentifierString} (${simData.primaryCell.cellIdentifier})"
                            : "${simData.primaryCell.nodeIdentifierString}/CID (${(int.tryParse(simData.primaryCell.cellIdentifier)! / factor).floor()}/${int.tryParse(simData.primaryCell.cellIdentifier)! % factor})")),
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      overlayColor: Theme.of(
                        context,
                      ).colorScheme.onPrimaryContainer.withAlpha(35),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      //margin: EdgeInsets.only(bottom: 5),
                      padding: EdgeInsets.zero,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                    ),
                    onPressed: () {
                      setState(() {
                        altCellView = !altCellView;
                      });
                    },
                    child: Ink(
                      width: cardWidth * 2,
                      height: (cardHeight * 2) - 20,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            (altCellView
                                ? simData.primaryCell.cellIdentifierString
                                : "${simData.primaryCell.nodeIdentifierString}/CID"),
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                            ),
                          ),
                          SizedBox(height: 3),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(
                                Icons.cell_tower_rounded,
                                size: 40,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                              ),
                              SizedBox(width: 6),
                              Text(
                                (simData.primaryCell.cellIdentifier.contains(
                                          "-1",
                                        ) ||
                                        simData.primaryCell.cellIdentifier ==
                                            "0"
                                    ? "Unknown"
                                    : (altCellView
                                          ? simData.primaryCell.cellIdentifier
                                          : "${(int.tryParse(simData.primaryCell.cellIdentifier)! / factor).floor()}/${int.tryParse(simData.primaryCell.cellIdentifier)! % factor}")),
                                style: TextStyle(
                                  fontSize: 24,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                ),
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
          ],
        ),
      );

      int timingAdvanceDistance = 0;
      if (simData.primaryCell.channelNumberString == "ARFCN") {
        // terrible (yet working) way of detecting gsm...
        timingAdvanceDistance = simData.primaryCell.timingAdvance * 550;
      } else {
        timingAdvanceDistance = simData.primaryCell.timingAdvance * 78; // 78.12
      }

      final List<String> elements = [
        simData.primaryCell.rawSignalString,
        "${simData.primaryCell.rawSignal}dBm",
        simData.primaryCell.processedSignalString,
        "${simData.primaryCell.processedSignal}dBm",
        simData.primaryCell.signalQualityString,
        "${simData.primaryCell.signalQuality}dB",
        simData.primaryCell.signalNoiseString,
        "${simData.primaryCell.signalNoise}dB",
        simData.primaryCell.channelNumberString,
        simData.primaryCell.channelNumber.toString(),
        simData.primaryCell.stationIdentityString,
        simData.primaryCell.stationIdentity.toString(),
        simData.primaryCell.areaCodeString,
        simData.primaryCell.areaCode.toString(),
        simData.primaryCell.timingAdvanceString,
        (timingAdvanceDistance <= 0
            ? simData.primaryCell.timingAdvance.toString()
            : "${simData.primaryCell.timingAdvance} (${timingAdvanceDistance}m)"),
        simData.primaryCell.bandwidthString,
        "${simData.activeBw}MHz",
        simData.primaryCell.bandString,
        simData.primaryCell.band.toString(),
      ];

      final List<Widget> validCards = [];

      for (int i = 0; i < elements.length - 1; i += 2) {
        final String label = elements[i];
        final String val = elements[i + 1];

        if (!isValidString(val) || !isValidString(label)) {
          continue;
        }

        validCards.add(
          Tooltip(
            message: label,
            child: Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withAlpha(230),
              child: Container(
                width: cardWidth,
                height: cardHeight,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ListTile(
                      title: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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
        );
      }

      for (int i = 0; i < validCards.length; i += 2) {
        final Widget leftCard = validCards[i];
        final Widget rightCard = (i + 1 < validCards.length)
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

      int? node = int.tryParse(simData.primaryCell.cellIdentifier);

      final List<CellData> tempActiveData = simData.activeCells;
      if (simData.primaryCell.cellIdentifier.contains("-1") ||
          simData.primaryCell.cellIdentifier == "0") {
        tempActiveData.clear();
      }

      tempActiveData.sort(
        (a, b) => (b.isRegistered ? 1 : 0).compareTo(a.isRegistered ? 1 : 0),
      );

      final List<Widget> activeData = tempActiveData.map((cell) {
        int i = simData.activeCells.indexOf(cell);

        String cellContent = createCellContent(cell).replaceAll(
          "%node%",
          (node != null ? "Likely ${(node / factor).floor()}" : "Unknown cell"),
        );

        List<IconData> icons = [
          Icons.signal_cellular_0_bar_rounded,
          Icons.signal_cellular_4_bar_rounded,
          Icons.auto_awesome_outlined,
          Icons.auto_awesome_rounded,
          Icons.question_mark,
        ];

        int index = 4;

        if (isValidInt(cell.processedSignal)) {
          index =
              ((min(
                            max(simData.primaryCell.processedSignal, minRsrp),
                            (maxRsrp - 15),
                          ) -
                          minRsrp) /
                      (((maxRsrp - 15) - minRsrp) / 2))
                  .floor();
        } else if (isValidInt(cell.rawSignal)) {
          index =
              ((min(
                            max(simData.primaryCell.rawSignal, minRssi),
                            (maxRssi - 15),
                          ) -
                          minRssi) /
                      (((maxRssi - 15) - minRssi) / 2))
                  .floor();
        }

        if (index != 4 && cell.isRegistered) index += 2;

        return Column(
          children: [
            ListTile(
              title: Text(
                (cell.basicCellData.band > 0
                    ? "${cell.channelNumberString == "NR-ARFCN" ? "N" : "B"}${cell.basicCellData.band} ${isValidInt(cell.basicCellData.frequency) ? "(${cell.basicCellData.frequency}MHz)" : ""}"
                    : "Unknown band"),
              ),
              subtitle: Text(cellContent),
              trailing: Icon(
                icons[index],
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        );
      }).toList();

      final List<Widget> neighborData = simData.neighborCells.map((cell) {
        int i = simData.neighborCells.indexOf(cell);

        String cellContent = createCellContent(cell).replaceAll(
          "%node%",
          (node != null && node != 0
              ? "Likely ${(node / factor).floor()}"
              : "Unknown cell"),
        );

        return Column(
          children: [
            ListTile(
              title: Text(
                "${cell.channelNumberString == "NR-ARFCN" ? "N" : "B"}${cell.basicCellData.band} ${isValidInt(cell.basicCellData.frequency) ? "(${cell.basicCellData.frequency}MHz)" : ""}",
              ),
              subtitle: Text(cellContent),
            ),
            if (i != simData.neighborCells.length - 1)
              Container(
                margin: EdgeInsets.only(left: 5, right: 5),
                child: Divider(
                  height: 0,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
          ],
        );
      }).toList();

      setState(() {
        _mainData = mainData;
        _activeData = activeData;
        _neighborData = neighborData;
        _progressIndicator = SizedBox.shrink();
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
    final widgetsHeight =
        MediaQuery.of(context).size.height -
        kToolbarHeight -
        kBottomNavigationBarHeight -
        MediaQuery.of(context).padding.top;

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Column(
        children: <Widget>[
          if (!homeLoadedNotifier.value)
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: widgetsHeight),
              child: Center(
                //test
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[CircularProgressIndicator()],
                ),
              ),
            )
          else if (homeLoadedNotifier.value && plmn.isEmpty && pageLoaded)
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: widgetsHeight),
              child: Center(
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
              ),
            )
          else
            Column(
              children: [
                Row(children: [Expanded(child: _progressIndicator)]),
                Container(
                  margin: EdgeInsets.all(10.0),
                  child: Column(children: _mainData),
                ),
                if (_activeData.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
                    child: Text(
                      "Active Cells",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: _activeData,
                    ),
                  ),
                ],
                if (_neighborData.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
                    child: Text(
                      "Neighbor Cells",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: _neighborData,
                    ),
                  ),
                ],
                if (debugNotifier.value &&
                    _debug.isNotEmpty &&
                    _debug != "null")
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
          ((min(
                        max(simData.primaryCell.processedSignal, minRsrp),
                        (maxRsrp - 15),
                      ) -
                      minRsrp) /
                  (((maxRsrp - 15) - minRsrp) / 3))
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
    } else if (val == simData.primaryCell.bandString) {
      //Band
      return Icon(Icons.numbers_rounded);
    }

    return Icon(Icons.question_mark); //Unknown icon
  }

  String createCellContent(CellData cell) {
    String cellContent = "";
    int factor = conversionFactor(cell);

    int? cellId = int.tryParse(cell.cellIdentifier);
    if (cellId != null && isValidString(cell.cellIdentifier) && cellId != 0) {
      cellContent += "${(cellId / factor).floor()}/${cellId % factor}, ";
    } else if (cell.isRegistered) {
      cellContent += "%node%, ";
    } else {
      cellContent += "Unknown cell, ";
    }

    if (isValidInt(cell.bandwidth) && isValidString(cell.bandwidthString)) {
      cellContent += "${cell.bandwidthString}: ${cell.bandwidth}MHz";
    } else {
      cellContent += "Unknown bandwidth";
    }

    cellContent += ".\n";

    if (isValidInt(cell.areaCode) && isValidString(cell.areaCodeString)) {
      cellContent += "${cell.areaCodeString}: ${cell.areaCode}, ";
    }

    if (isValidInt(cell.channelNumber) &&
        isValidString(cell.channelNumberString)) {
      cellContent += "${cell.channelNumberString}: ${cell.channelNumber}, ";
    }

    if (isValidInt(cell.stationIdentity) &&
        isValidString(cell.stationIdentityString)) {
      cellContent += "${cell.stationIdentityString}: ${cell.stationIdentity}, ";
    }

    if (isValidInt(cell.timingAdvance) &&
        isValidString(cell.timingAdvanceString)) {
      cellContent += "${cell.timingAdvanceString}: ${cell.timingAdvance}";
    }

    if (cellContent.endsWith(", ")) {
      cellContent = cellContent.substring(0, cellContent.length - 2);
    }

    cellContent += ".\n";
    cellContent.replaceAll("\n.\n", "\n");

    if (isValidInt(cell.processedSignal) &&
        isValidString(cell.processedSignalString)) {
      cellContent +=
          "${cell.processedSignalString} ${cell.processedSignal}dBm, ";
    } else if (isValidInt(cell.rawSignal) &&
        isValidString(cell.rawSignalString)) {
      cellContent += "${cell.rawSignalString} ${cell.rawSignal}dBm, ";
    }

    if (isValidInt(cell.signalQuality) &&
        isValidString(cell.signalQualityString)) {
      cellContent += "${cell.signalQualityString} ${cell.signalQuality}dB, ";
    }

    if (isValidInt(cell.signalNoise) && isValidString(cell.signalNoiseString)) {
      cellContent += "${cell.signalNoiseString} ${cell.signalNoise}dB";
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
    // todo: find a better way to sanitise data
    return !(val == -1 || val == 2147483647 || val == 268435455);
  }

  bool isValidString(String val) {
    // todo: find a better way to sanitise data
    return !((val.contains("-1") &&
            (!val.endsWith("dB") && !val.contains("dB"))) ||
        val.contains("2147483647") ||
        val.contains("268435455") ||
        val.contains("null") ||
        val.contains("-1dBm") ||
        val.trim() == "0.0" ||
        val.trim() == "0.0MHz" ||
        val.trim() == "-1MHz" ||
        val.trim() == "-1.0MHz" ||
        val.trim() == "-" ||
        val.trim().isEmpty);
  }

  int conversionFactor(CellData cellData) {
    // to be improved
    int factor = 256; // wcdma, tdscdma, lte, nr

    if (cellData.channelNumberString == "ARFCN") {
      factor = 64; // gsm
    } else if (cellData.stationIdentityString == "PN") {
      factor = 1; // cdma
    }

    return factor;
  }

  void startTimer() {
    update();

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;

      update();
      pageLoaded = true;
      homeLoadedNotifier.value = true;
    });

    timer = Timer.periodic(
      Duration(seconds: sharedPreferences.getInt("updateInterval") ?? 3),
      (Timer t) {
        update();
      },
    );
  }

  void restartTimer() {
    timer.cancel();
    altCellView = false;
    startTimer();
  }
}
