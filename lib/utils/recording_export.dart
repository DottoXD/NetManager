import 'package:material_ui/material_ui.dart';
import 'package:netmanager/types/cell/cell_data.dart';
import 'package:netmanager/types/cell/sim_data.dart';
import 'package:netmanager/types/recording/record.dart';
import 'package:netmanager/types/recording/recorded_data.dart';
import 'package:netmanager/utils/cell_utils.dart';
import 'package:netmanager/utils/format_utils.dart';
import 'package:netmanager/utils/signal_color.dart';

String _kmlColorForRecord(Record record) {
  final Color signalColor = getSignalColor(
    record.networkGen,
    record.processedSignal,
  );
  final double fixedAlpha = signalColor.a * (record.usable ? 1.0 : 0.2);

  int channel(double v) => (v * 255).round().clamp(0, 255);

  final String aa = channel(fixedAlpha).toRadixString(16).padLeft(2, "0");
  final String bb = channel(signalColor.b).toRadixString(16).padLeft(2, "0");
  final String gg = channel(signalColor.g).toRadixString(16).padLeft(2, "0");
  final String rr = channel(signalColor.r).toRadixString(16).padLeft(2, "0");

  return "$aa$bb$gg$rr";
}

String _genLabel(int gen) {
  switch (gen) {
    case 5:
      return "5G";
    case 4:
      return "4G";
    case 3:
      return "3G";
    case 2:
      return "2G";
    default:
      return "Unknown";
  }
}

String _xmlEscape(String value) {
  return value
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;");
}

String _cleanInt(int? val) {
  if (val == null || !isValidInt(val)) return "";
  return val.toString();
}

String _cleanStr(String? val) {
  if (val == null || !isValidString(val)) return "";
  return val;
}

String recordedDataToKml(RecordedData data) {
  final StringBuffer buffer = StringBuffer();

  buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
  buffer.writeln(
    '<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">',
  );
  buffer.writeln("<Document>");
  buffer.writeln(
    "<name>${_xmlEscape("${data.operator} - ${data.network}")}</name>",
  );

  final Map<String, String> styleIdByColor = {};
  int styleCounter = 0;

  for (final Record record in data.records) {
    final String color = _kmlColorForRecord(record);

    if (!styleIdByColor.containsKey(color)) {
      final String styleId = "s${styleCounter++}";

      styleIdByColor[color] = styleId;
      buffer.writeln('<Style id="$styleId">');
      buffer.writeln("<IconStyle>");
      buffer.writeln("<color>$color</color>");
      buffer.writeln("<scale>0.8</scale>");
      buffer.writeln(
        "<Icon><href>https://maps.google.com/mapfiles/kml/shapes/placemark_circle.png</href></Icon>",
      );
      buffer.writeln("</IconStyle>");
      buffer.writeln("</Style>");
    }
  }

  for (final Record record in data.records) {
    final String styleId = styleIdByColor[_kmlColorForRecord(record)]!;
    final SIMData? sim = record.simData;
    final CellData? cell = sim?.primaryCell;

    final StringBuffer desc = StringBuffer();
    desc.write("<b>Time:</b> ${record.dateTime.toIso8601String()}<br/>");
    desc.write("<b>Usable:</b> ${record.usable ? "Yes" : "No"}<br/>");
    desc.write("<b>Technology:</b> ${_genLabel(record.networkGen)}<br/>");

    final String op = _cleanStr(sim?.operator ?? data.operator);
    if (op.isNotEmpty) desc.write("<b>Operator:</b> ${_xmlEscape(op)}<br/>");

    final String net = _cleanStr(sim?.network ?? data.network);
    if (net.isNotEmpty) desc.write("<b>Network:</b> ${_xmlEscape(net)}<br/>");

    if (sim != null) {
      if (isValidString(sim.homePlmn)) {
        desc.write("<b>Home PLMN:</b> ${_xmlEscape(sim.homePlmn)}<br/>");
      }
      if (isValidString(sim.networkPlmn)) {
        desc.write("<b>Network PLMN:</b> ${_xmlEscape(sim.networkPlmn)}<br/>");
      }
      if (sim.activeBw > 0) {
        desc.write("<b>Active BW:</b> ${sim.activeBw}MHz<br/>");
      }
    }

    if (cell != null &&
        isValidString(cell.processedSignalString) &&
        isValidInt(cell.processedSignal)) {
      desc.write(
        "<b>${_xmlEscape(cell.processedSignalString)}:</b> ${cell.processedSignal}dBm<br/>",
      );
    } else if (isValidInt(record.processedSignal)) {
      desc.write("<b>Signal:</b> ${record.processedSignal}dBm<br/>");
    }

    if (cell != null) {
      if (isValidString(cell.cellIdentifierString) &&
          isValidString(cell.cellIdentifier)) {
        desc.write(
          "<b>${_xmlEscape(cell.cellIdentifierString)}:</b> ${_xmlEscape(cell.cellIdentifier)}<br/>",
        );
      }
      if (isValidString(cell.rawSignalString) && isValidInt(cell.rawSignal)) {
        desc.write(
          "<b>${_xmlEscape(cell.rawSignalString)}:</b> ${cell.rawSignal}dBm<br/>",
        );
      }
      if (isValidString(cell.signalQualityString) &&
          isValidInt(cell.signalQuality)) {
        desc.write(
          "<b>${_xmlEscape(cell.signalQualityString)}:</b> ${cell.signalQuality}dB<br/>",
        );
      }
      if (isValidString(cell.signalNoiseString) &&
          isValidInt(cell.signalNoise)) {
        desc.write(
          "<b>${_xmlEscape(cell.signalNoiseString)}:</b> ${cell.signalNoise}dB<br/>",
        );
      }
      if (isValidString(cell.channelQualityString) &&
          isValidInt(cell.channelQuality)) {
        desc.write(
          "<b>${_xmlEscape(cell.channelQualityString)}:</b> ${cell.channelQuality}<br/>",
        );
      }
      if (isValidString(cell.areaCodeString) && isValidInt(cell.areaCode)) {
        desc.write(
          "<b>${_xmlEscape(cell.areaCodeString)}:</b> ${cell.areaCode}<br/>",
        );
      }
      if (isValidString(cell.channelNumberString) &&
          isValidInt(cell.channelNumber)) {
        desc.write(
          "<b>${_xmlEscape(cell.channelNumberString)}:</b> ${cell.channelNumber}<br/>",
        );
      }
      if (isValidString(cell.stationIdentityString) &&
          isValidInt(cell.stationIdentity)) {
        desc.write(
          "<b>${_xmlEscape(cell.stationIdentityString)}:</b> ${cell.stationIdentity}<br/>",
        );
      }
      if (isValidString(cell.timingAdvanceString) &&
          isValidInt(cell.timingAdvance)) {
        desc.write(
          "<b>${_xmlEscape(cell.timingAdvanceString)}:</b> ${cell.timingAdvance}<br/>",
        );
      }
      if (isValidString(cell.bandwidthString) && isValidInt(cell.bandwidth)) {
        desc.write(
          "<b>${_xmlEscape(cell.bandwidthString)}:</b> ${cell.bandwidth}MHz<br/>",
        );
      }
      if (isValidString(cell.bandString) && isValidInt(cell.band)) {
        desc.write("<b>${_xmlEscape(cell.bandString)}:</b> ${cell.band}<br/>");
      }
    }

    buffer.writeln("<Placemark>");
    buffer.writeln("<name>${_xmlEscape(_genLabel(record.networkGen))}</name>");
    buffer.writeln("<description><![CDATA[${desc.toString()}]]></description>");
    buffer.writeln("<styleUrl>#$styleId</styleUrl>");
    buffer.writeln(
      "<Point><coordinates>${record.lon},${record.lat},0</coordinates></Point>",
    );
    buffer.writeln("</Placemark>");
  }

  if (data.records.length > 1) {
    buffer.writeln("<Placemark>");
    buffer.writeln("<name>Route</name>");
    buffer.writeln(
      "<Style><LineStyle><color>ff0080ff</color><width>3</width></LineStyle></Style>",
    );
    buffer.writeln("<LineString>");
    buffer.writeln("<tessellate>1</tessellate>");
    buffer.write("<coordinates>");
    for (final Record record in data.records) {
      buffer.write("${record.lon},${record.lat},0 ");
    }
    buffer.writeln("</coordinates>");
    buffer.writeln("</LineString>");
    buffer.writeln("</Placemark>");
  }

  buffer.writeln("</Document>");
  buffer.writeln("</kml>");

  return buffer.toString();
}

String recordedDataToCsv(RecordedData data) {
  const separator = ",";
  final StringBuffer buffer = StringBuffer();

  final List<String> headers = [
    "Timestamp",
    "Latitude",
    "Longitude",
    "Usable",
    "Operator",
    "Network",
    "Generation",
    "Home PLMN",
    "Network PLMN",
    "Total BW",
    "Cell ID",
    "Raw Signal",
    "Processed Signal",
    "Signal Quality",
    "Signal Noise",
    "Channel Quality",
    "Area Code",
    "Channel Number",
    "Station Identity",
    "Timing Advance",
    "Bandwidth",
    "Band",
  ];

  buffer.writeln(encodeRow(headers, separator));

  for (final Record record in data.records) {
    final SIMData? sim = record.simData;
    final CellData? cell = sim?.primaryCell;

    final List<String> row = [
      record.dateTime.toIso8601String(),
      record.lat.toString(),
      record.lon.toString(),
      record.usable ? "Yes" : "No",
      _cleanStr(sim?.operator ?? data.operator),
      _cleanStr(sim?.network ?? data.network),
      _cleanInt(record.networkGen),
      _cleanStr(sim?.homePlmn),
      _cleanStr(sim?.networkPlmn),
      (sim != null && sim.activeBw > 0) ? sim.activeBw.toString() : "",
      _cleanStr(cell?.cellIdentifier),
      _cleanInt(cell?.rawSignal),
      _cleanInt(record.processedSignal),
      _cleanInt(cell?.signalQuality),
      _cleanInt(cell?.signalNoise),
      _cleanInt(cell?.channelQuality),
      _cleanInt(cell?.areaCode),
      _cleanInt(cell?.channelNumber),
      _cleanInt(cell?.stationIdentity),
      _cleanInt(cell?.timingAdvance),
      _cleanInt(cell?.bandwidth),
      _cleanInt(cell?.band),
    ];

    buffer.writeln(encodeRow(row, separator));
  }

  return buffer.toString();
}
