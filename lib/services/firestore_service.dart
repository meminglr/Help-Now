import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ihtiyac.dart';
import '../models/teklif.dart';

class FirestoreService {
  final CollectionReference _ihtiyaclar = FirebaseFirestore.instance.collection(
    'ihtiyaclar',
  );
  final CollectionReference _teklifler = FirebaseFirestore.instance.collection(
    'teklifler',
  );

  // İhtiyacı Firestore’a kaydet
  Future<void> addIhtiyac(Ihtiyac ihtiyac) async {
    try {
      await _ihtiyaclar.doc(ihtiyac.id).set(ihtiyac.toMap());
    } catch (e) {
      print('İhtiyaç kaydetme hatası: $e');
      rethrow;
    }
  }

  // İhtiyaçları anlık olarak çek
  Stream<List<Ihtiyac>> getIhtiyaclar() {
    return _ihtiyaclar.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => Ihtiyac.fromMap(doc.data() as Map<String, dynamic>))
          .toList(),
    );
  }

  // İhtiyacın durumunu güncelle (kurumlar için)
  Future<void> updateIhtiyacDurum(String ihtiyacId, String yeniDurum) async {
    try {
      await _ihtiyaclar.doc(ihtiyacId).update({'durum': yeniDurum});
    } catch (e) {
      print('İhtiyaç durumu güncelleme hatası: $e');
      rethrow;
    }
  }

  // İhtiyacı sil (kurumlar için)
  Future<void> deleteIhtiyac(String ihtiyacId) async {
    try {
      await _ihtiyaclar.doc(ihtiyacId).delete();
    } catch (e) {
      print('İhtiyaç silme hatası: $e');
      rethrow;
    }
  }

  // Teklifi Firestore’a kaydet
  Future<void> addTeklif(Teklif teklif) async {
    try {
      await _teklifler.doc(teklif.id).set(teklif.toMap());
    } catch (e) {
      print('Teklif kaydetme hatası: $e');
      rethrow;
    }
  }

  // Teklifleri anlık olarak çek
  Stream<List<Teklif>> getTeklifler(String ihtiyacId) {
    return _teklifler
        .where('ihtiyacId', isEqualTo: ihtiyacId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Teklif.fromMap(doc.data() as Map<String, dynamic>))
              .toList(),
        );
  }
}
