import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ihtiyac.dart';

class FirestoreService {
  final CollectionReference _ihtiyaclar = FirebaseFirestore.instance.collection(
    'ihtiyaclar',
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
}
