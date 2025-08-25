import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ihtiyac.dart';
import '../models/envanter.dart';

class FirestoreService {
  final CollectionReference _ihtiyaclar = FirebaseFirestore.instance.collection(
    'ihtiyaclar',
  );
  final CollectionReference _teklifler = FirebaseFirestore.instance.collection(
    'teklifler',
  );
  final CollectionReference _users = FirebaseFirestore.instance.collection(
    'users',
  );
  final CollectionReference _envanter = FirebaseFirestore.instance.collection(
    'envanter',
  );
  final CollectionReference _eksikIstekler = FirebaseFirestore.instance
      .collection('eksik_istekler');

  // Envanter işlemleri
  Future<void> addEnvanterItem(EnvanterItem item) async {
    await _envanter.doc(item.id).set(item.toMap());
  }

  Stream<List<EnvanterItem>> getEnvanter() {
    return _envanter.snapshots().map(
      (snapshot) => snapshot.docs
          .map(
            (doc) => EnvanterItem.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList(),
    );
  }

  Future<void> updateEnvanterMiktar(String itemId, int yeniMiktar) async {
    await _envanter.doc(itemId).update({'miktar': yeniMiktar});
  }

  // İhtiyaç ekleme
  Future<void> addIhtiyac(Ihtiyac ihtiyac) async {
    await _ihtiyaclar.doc(ihtiyac.id).set(ihtiyac.toMap());
  }

  // İhtiyaçları alma
  Stream<List<Ihtiyac>> getIhtiyaclar() {
    return _ihtiyaclar.snapshots().map(
      (snapshot) => snapshot.docs
          .map(
            (doc) =>
                Ihtiyac.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList(),
    );
  }

  // İhtiyaç durumunu güncelleme
  Future<void> updateIhtiyacDurum(String ihtiyacId, String durum) async {
    await _ihtiyaclar.doc(ihtiyacId).update({'durum': durum});
  }

  // İhtiyacı silme
  Future<void> deleteIhtiyac(String ihtiyacId) async {
    await _ihtiyaclar.doc(ihtiyacId).delete();
  }

  // Teklif ekleme
  /* Future<void> addTeklif(Teklif teklif) async {
    await _teklifler.doc(teklif.id).set({
      'ihtiyacId': teklif.ihtiyacId,
      'gonulluId': teklif.gonulluId,
      'aciklama': teklif.aciklama,
      'timestamp': teklif.timestamp,
    });
  } */

  // Eksik envanter isteği ekleme
  Future<void> addEksikIstek(
    String ihtiyacId,
    Map<String, int> eksikUrunler,
  ) async {
    await _eksikIstekler.doc(ihtiyacId).set({
      'ihtiyacId': ihtiyacId,
      'eksikUrunler': eksikUrunler,
      'durum': 'beklemede',
      'timestamp': DateTime.now(),
    });
  }

  // Eksik istekleri alma
  Stream<List<Map<String, dynamic>>> getEksikIstekler() {
    return _eksikIstekler.snapshots().map(
      (snapshot) => snapshot.docs
          .map(
            (doc) => {
              'id': doc.id,
              'ihtiyacId': doc['ihtiyacId'],
              'eksikUrunler': Map<String, int>.from(doc['eksikUrunler'] ?? {}),
              'durum': doc['durum'] ?? 'beklemede',
              'timestamp':
                  (doc['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
            },
          )
          .toList(),
    );
  }

  // Eksik isteği güncelleme
  Future<void> updateEksikIstekDurum(String istekId, String durum) async {
    await _eksikIstekler.doc(istekId).update({'durum': durum});
  }

  // Kullanıcı profili güncelleme
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _users.doc(uid).update(data);
  }
}
