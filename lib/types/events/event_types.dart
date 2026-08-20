enum EventTypes {
  MOBILE_BAND_CHANGED,
  MOBILE_PLMN_CHANGED,
  MOBILE_TECHNOLOGY_CHANGED,
  MOBILE_NODE_CHANGED,
  MOBILE_DATA_SIM_CHANGED,
  MOBILE_NETWORK_CHANGED,
}

EventTypes eventTypeFromString(String type) {
  return EventTypes.values.firstWhere(
    (e) => e.toString().split(".").last == type,
  );
}

String formatEventName(String name) {
  String finalName = name
      .replaceFirst("MOBILE_", "")
      .replaceAll("_", " ")
      .toUpperCase();

  return finalName;
}
