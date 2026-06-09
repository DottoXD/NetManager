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

  @override
  bool operator ==(Object other) => other is DatabaseCell && other.cid == cid;

  @override
  int get hashCode => cid.hashCode;
}
