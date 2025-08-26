import 'package:cloud_firestore/cloud_firestore.dart';

class Ihtiyac {
  final String id;
  final String userId;
  final Map<String, int> urunler;
  final String isim;
  final String soyisim;
  final String adresTarifi;
  final String not;
  final String durum;
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  Ihtiyac({
    required this.id,
    required this.userId,
    required this.urunler,
    required this.isim,
    required this.soyisim,
    required this.adresTarifi,
    required this.not,
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
      'isim': isim,
      'soyisim': soyisim,
      'adresTarifi': adresTarifi,
      'not': not,
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
      isim: map['isim'] ?? '',
      soyisim: map['soyisim'] ?? '',
      adresTarifi: map['adresTarifi'] ?? '',
      not: map['not'] ?? '',
      durum: map['durum'] ?? 'beklemede',
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
