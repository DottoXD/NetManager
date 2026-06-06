import 'dart:convert';
import 'dart:io';

Future<String?> extractPlmnFromFirstLine(String path, bool isClf) async {
  final file = File(path);
  if (!file.existsSync()) return null;

  final lines = file
      .openRead()
      .transform(utf8.decoder)
      .transform(const LineSplitter());

  await for (final line in lines) {
    if (line.trim().isEmpty || line.startsWith("#")) continue;
    final parts = line.split(";");

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
