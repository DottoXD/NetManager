class BasicCellData {
  final int band;
  final int frequency;

  BasicCellData({required this.band, required this.frequency});

  factory BasicCellData.fromJson(Map<String, dynamic> json) {
    return BasicCellData(band: json["band"], frequency: json["frequency"]);
  }
}
