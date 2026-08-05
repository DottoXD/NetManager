import 'dart:convert';
import 'dart:io';

import 'package:netmanager/utils/format_utils.dart';

Future<String?> extractPlmnFromFirstLine(String path, bool isClf) async {
  final file = File(path);
  if (!file.existsSync()) return null;

  final Stream<String> lines;

  try {
    lines = file
        .openRead()
        .transform(utf8.decoder)
        .transform(const LineSplitter());
  } catch (e) {
    return null;
  }

  await for (final line in lines) {
    if (line.trim().isEmpty || line.startsWith("#")) continue;
    final parts = decodeRow(line, ";");

    try {
      if (isClf) {
        if (parts.isNotEmpty && parts[0].length >= 5) {
          return parts[0];
        }
      } else {
        if (parts.length >= 3) {
          return "${parts[1]}${parts[2]}";
        }
      }
    } catch (_) {
      return null;
    }
  }
  return null;
}
