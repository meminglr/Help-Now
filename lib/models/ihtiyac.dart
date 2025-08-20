import 'package:cloud_firestore/cloud_firestore.dart';

class Ihtiyac {
  final String id;
  final String userId;
  final String kategori; // Gıda, Su, Barınma, Sağlık
  final String aciklama;
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  Ihtiyac({
    required this.id,
    required this.userId,
    required this.kategori,
    required this.aciklama,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  // Firestore’dan veri çekmek için
  factory Ihtiyac.fromMap(Map<String, dynamic> data) {
    return Ihtiyac(
      id: data['id'] ?? '',
      userId: data['userId'] ?? '',
      kategori: data['kategori'] ?? '',
      aciklama: data['aciklama'] ?? '',
      latitude: data['latitude']?.toDouble() ?? 0.0,
      longitude: data['longitude']?.toDouble() ?? 0.0,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  // Firestore’a veri kaydetmek için
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'kategori': kategori,
      'aciklama': aciklama,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp,
    };
  }
}
