class EnvanterItem {
  final String id;
  final String ad;
  final int miktar;

  EnvanterItem({required this.id, required this.ad, required this.miktar});

  Map<String, dynamic> toMap() {
    return {'id': id, 'ad': ad, 'miktar': miktar};
  }

  factory EnvanterItem.fromMap(Map<String, dynamic> map, String id) {
    return EnvanterItem(
      id: id,
      ad: map['ad'] ?? '',
      miktar: map['miktar'] ?? 0,
    );
  }
}
