import 'package:cloud_firestore/cloud_firestore.dart';

class Teklif {
  final String id;
  final String ihtiyacId;
  final String gonulluId;
  final String aciklama;
  final DateTime timestamp;

  Teklif({
    required this.id,
    required this.ihtiyacId,
    required this.gonulluId,
    required this.aciklama,
    required this.timestamp,
  });

  factory Teklif.fromMap(Map<String, dynamic> data) {
    return Teklif(
      id: data['id'] ?? '',
      ihtiyacId: data['ihtiyacId'] ?? '',
      gonulluId: data['gonulluId'] ?? '',
      aciklama: data['aciklama'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ihtiyacId': ihtiyacId,
      'gonulluId': gonulluId,
      'aciklama': aciklama,
      'timestamp': timestamp,
    };
  }
}
