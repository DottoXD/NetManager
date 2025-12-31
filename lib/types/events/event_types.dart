enum EventTypes {
  MOBILE_BAND_CHANGED,
  MOBILE_PLMN_CHANGED,
  MOBILE_TECHNOLOGY_CHANGED,
  MOBILE_NODE_CHANGED,
}

EventTypes eventTypeFromString(String type) {
  return EventTypes.values.firstWhere(
    (e) => e.toString().split(".").last == type,
  );
}
