const defaultMapTileTemplate = "https://tile.openstreetmap.org/{z}/{x}/{y}.png";

bool isValidMapTileTemplate(String template) {
  final value = template.trim();
  final uri = Uri.tryParse(value);

  if (uri == null ||
      (uri.scheme != "https" && uri.scheme != "http") ||
      uri.host.isEmpty) {
    return false;
  }

  for (final coord in ["z", "x", "y"]) {
    if (!value.contains("{$coord}")) return false;
  }

  const allowed = {"z", "x", "y", "s", "r", "d"};
  final placeholderPattern = RegExp(r"\{([^{}]*)\}"); // weird regex
  for (final match in placeholderPattern.allMatches(value)) {
    if (!allowed.contains(match.group(1))) return false;
  }

  final remainder = value.replaceAll(placeholderPattern, "");
  return !remainder.contains("{") && !remainder.contains("}");
}
