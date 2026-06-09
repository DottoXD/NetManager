import 'dart:convert';

import 'package:netmanager/types/cell/sim_data.dart';

SIMData? parseSimData(String jsonStr) {
  try {
    if (jsonStr.trim().isEmpty || jsonStr == "null") {
      return null;
    }
    final Map<String, dynamic> map = json.decode(jsonStr);
    return SIMData.fromJson(map);
  } catch (e) {
    return null;
  }
}
