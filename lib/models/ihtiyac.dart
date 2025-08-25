import 'package:cloud_firestore/cloud_firestore.dart';

class Ihtiyac {
  final String id;
  final String userId;
  final Map<String, int> urunler; // Ürün ID’si ve miktarı
  final String durum; // beklemede, onaylandı, reddedildi, yetersiz
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  Ihtiyac({
    required this.id,
    required this.userId,
    required this.urunler,
    this.durum = 'beklemede',
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'urunler': urunler,
      'durum': durum,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp,
    };
  }

  factory Ihtiyac.fromMap(Map<String, dynamic> map, String id) {
    return Ihtiyac(
      id: id,
      userId: map['userId'] ?? '',
      urunler: Map<String, int>.from(map['urunler'] ?? {}),
      durum: map['durum'] ?? 'beklemede',
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
