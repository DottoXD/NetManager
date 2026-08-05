import 'package:flutter/material.dart';
import 'package:netmanager/types/recording/recorded_data.dart';
import 'package:netmanager/types/recording/record.dart';
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

    buffer.writeln("<Placemark>");
    buffer.writeln("<name>${_xmlEscape(_genLabel(record.networkGen))}</name>");
    buffer.writeln(
      "<description><![CDATA["
      "Signal: ${record.processedSignal} dBm<br/>"
      "Technology: ${_genLabel(record.networkGen)}<br/>"
      "Usable: ${record.usable}<br/>"
      "Time: ${record.dateTime.toIso8601String()}"
      "]]></description>",
    );
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

  buffer.writeln(
    ["Name", "Latitude", "Longitude", "Description"].join(separator),
  );

  for (final Record record in data.records) {
    final String name =
        "${_genLabel(record.networkGen)} - "
        "${record.dateTime.toIso8601String()}";

    final String description =
        "${data.operator} / ${data.network} | "
        "Signal: ${record.processedSignal} dBm | "
        "Usable: ${record.usable ? "Yes" : "No"}";

    buffer.writeln(
      encodeRow([
        name,
        record.lat.toString(),
        record.lon.toString(),
        description,
      ], separator),
    );
  }

  return buffer.toString();
}
