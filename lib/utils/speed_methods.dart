String formatSpeed(double speedInMbps, int unitIndex) {
  switch (unitIndex) {
    case 0:
      double gbps = speedInMbps / 1000;
      return gbps.toStringAsFixed(2);
    case 2:
      double kbps = speedInMbps * 1000;
      return kbps.toStringAsFixed(0);
    case 1:
    default:
      return speedInMbps.toStringAsFixed(speedInMbps > 10 ? 1 : 2);
  }
}

String getUnitString(int unitIndex) {
  const List<String> units = ["Gbps", "Mbps", "Kbps"];

  return units[unitIndex];
}
