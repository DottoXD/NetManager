class DatabaseCell {
  final int cid;
  final int networkGen;
  final String description;
  final int? channelNumber;

  DatabaseCell({
    required this.cid,
    required this.networkGen,
    required this.description,
    this.channelNumber,
  });
}
