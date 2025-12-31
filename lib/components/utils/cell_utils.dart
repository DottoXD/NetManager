import 'dart:math';

import 'package:flutter/material.dart';
import 'package:netmanager/types/cell/cell_data.dart';
import 'package:netmanager/types/cell/sim_data.dart';

final int minRssi = -113;
final int maxRssi = -51;

final int minRsrp = -140;
final int maxRsrp = -43;

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

IconData getTrailingIcon(SIMData simData, String val) {
  if (val == simData.primaryCell.rawSignalString) {
    //RSSI

    List<IconData> icons = [
      Icons.signal_cellular_alt_1_bar,
      Icons.signal_cellular_alt_2_bar,
      Icons.signal_cellular_alt,
    ];

    int index =
        ((min(max(simData.primaryCell.rawSignal, minRssi), maxRssi) - minRssi) /
                ((maxRssi - minRssi) / 3))
            .floor();

    return icons[min(index, 2)];
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

    return icons[min(index, 2)];
  } else if (val == simData.primaryCell.signalQualityString) {
    //SNR
    return Icons.settings_input_antenna_outlined;
  } else if (val == simData.primaryCell.signalNoiseString) {
    //RSRQ
    return Icons.spatial_tracking;
  } else if (val == simData.primaryCell.channelNumberString) {
    //EARFCN
    return Icons.wifi_channel;
  } else if (val == simData.primaryCell.stationIdentityString) {
    //PCI
    return Icons.perm_identity;
  } else if (val == simData.primaryCell.areaCodeString) {
    //TAC
    return Icons.landscape;
  } else if (val == simData.primaryCell.timingAdvanceString) {
    //TA
    return Icons.shortcut;
  } else if (val == simData.primaryCell.bandwidthString) {
    //BW
    return Icons.swap_horiz_rounded;
  } else if (val == simData.primaryCell.bandString) {
    //Band
    return Icons.numbers_rounded;
  }

  return Icons.question_mark; //Unknown icon
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
    cellContent += "Bandwidth: ${cell.bandwidth}MHz";
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
      isValidString(cell.timingAdvanceString) &&
      cell.isRegistered) {
    cellContent += "${cell.timingAdvanceString}: ${cell.timingAdvance}";
  }

  if (cellContent.endsWith(", ")) {
    cellContent = cellContent.substring(0, cellContent.length - 2);
  }

  cellContent += ".\n";
  cellContent.replaceAll("\n.\n", "\n");

  if (isValidInt(cell.processedSignal) &&
      isValidString(cell.processedSignalString)) {
    cellContent += "${cell.processedSignalString} ${cell.processedSignal}dBm, ";
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
  }

  if (cellContent.isEmpty) cellContent = "No info for this cell.";

  return cellContent;
}
