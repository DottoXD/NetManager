class DeviceData {
  final String manufacturer;
  final String modem;
  final String model;

  DeviceData({
    required this.manufacturer,
    required this.modem,
    required this.model,
  });

  factory DeviceData.fromJson(Map<String, dynamic> json) {
    return DeviceData(
      manufacturer: json["manufacturer"] ?? "Unknown",
      modem: json["modem"] ?? "Unknown",
      model: json["model"] ?? "Unknown",
    );
  }
}
