String encodeRow(List<String> fields, String separator) {
  return fields.map((field) => _escapeField(field, separator)).join(separator);
}

String _escapeField(String field, String separator) {
  if (field.contains(separator) ||
      field.contains('"') ||
      field.contains("\n")) {
    return '"${field.replaceAll('"', '""')}"';
  }

  return field;
}

List<String> decodeRow(String line, String separator) {
  final List<String> fields = [];
  final StringBuffer current = StringBuffer();
  bool inQuotes = false;

  for (int i = 0; i < line.length; i++) {
    final String char = line[i];

    if (inQuotes) {
      if (char == '"') {
        if (i + 1 < line.length && line[i + 1] == '"') {
          current.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        current.write(char);
      }
    } else {
      if (char == '"') {
        inQuotes = true;
      } else if (char == separator) {
        fields.add(current.toString());
        current.clear();
      } else {
        current.write(char);
      }
    }
  }

  fields.add(current.toString());
  return fields;
}
