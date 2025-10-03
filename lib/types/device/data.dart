class DeviceData {
  final String manufacturer;
  final String modem;

  DeviceData({required this.manufacturer, required this.modem});

  factory DeviceData.fromJson(Map<String, dynamic> json) {
    return DeviceData(
      manufacturer: json["manufacturer"] ?? "Unknown",
      modem: json["modem"] ?? "Unknown",
    );
  }
}
