import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ihtiyac.dart';
import '../models/envanter.dart';

class FirestoreService {
  final CollectionReference _ihtiyaclar = FirebaseFirestore.instance.collection(
    'ihtiyaclar',
  );
  final CollectionReference _users = FirebaseFirestore.instance.collection(
    'users',
  );
  final CollectionReference _envanter = FirebaseFirestore.instance.collection(
    'envanter',
  );
  final CollectionReference _hareketler = FirebaseFirestore.instance.collection(
    'envanter_hareketleri',
  );
  final CollectionReference _eksikIstekler = FirebaseFirestore.instance
      .collection('eksik_istekler');

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

  Stream<List<String>> getEnvanterAdlari() {
    return _envanter.snapshots().map((snapshot) {
      final names =
          snapshot.docs
              .map(
                (doc) =>
                    ((doc.data() as Map<String, dynamic>)['ad'] as String?)
                        ?.trim() ??
                    '',
              )
              .where((name) => name.isNotEmpty)
              .toSet()
              .toList()
            ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      return names;
    });
  }

  Future<void> updateEnvanterMiktar(String itemId, int yeniMiktar) async {
    final DocumentReference docRef = _envanter.doc(itemId);
    // Mevcut miktarı oku, sonra güncelle ve hareket kaydı oluştur
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      int eskiMiktar = 0;
      String ad = itemId;
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        eskiMiktar = (data['miktar'] as int?) ?? 0;
        ad = (data['ad'] as String?) ?? itemId;
      }
      transaction.update(docRef, {'miktar': yeniMiktar});

      final int degisim = yeniMiktar - eskiMiktar;
      if (degisim != 0) {
        final hareketRef = _hareketler.doc();
        transaction.set(hareketRef, {
          'itemId': itemId,
          'ad': ad,
          'degisim': degisim,
          'tur': degisim > 0 ? 'giris' : 'cikis',
          'kaynak': 'manuel_guncelleme',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<void> donateEnvanter(String ad, int miktar) async {
    final String normalizedId = _normalizeProductId(ad);

    if (normalizedId.isEmpty) {
      throw Exception('Geçerli bir ürün adı giriniz');
    }

    final DocumentReference docRef = _envanter.doc(normalizedId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final int current = (data['miktar'] as int?) ?? 0;
        transaction.update(docRef, {'ad': ad, 'miktar': current + miktar});
      } else {
        transaction.set(docRef, {
          'id': normalizedId,
          'ad': ad,
          'miktar': miktar,
        });
      }

      final hareketRef = _hareketler.doc();
      transaction.set(hareketRef, {
        'itemId': normalizedId,
        'ad': ad,
        'degisim': miktar,
        'tur': 'giris',
        'kaynak': 'bagis',
        'timestamp': FieldValue.serverTimestamp(),
      });
    });
  }

  String _normalizeProductId(String name) {
    String s = name.trim().toLowerCase();
    const Map<String, String> trMap = {
      'ç': 'c',
      'ğ': 'g',
      'ı': 'i',
      'ö': 'o',
      'ş': 's',
      'ü': 'u',
      'â': 'a',
      'î': 'i',
      'û': 'u',
    };
    trMap.forEach((k, v) => s = s.replaceAll(k, v));
    s = s
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return s;
  }

  Stream<Map<String, int>> getGunlukGirisCikis() {
    final DateTime now = DateTime.now();
    final DateTime startOfDay = DateTime(now.year, now.month, now.day);
    return _hareketler
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .snapshots()
        .map((snapshot) {
          int giris = 0;
          int cikis = 0;
          for (final doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final int degisim = (data['degisim'] as int?) ?? 0;
            if (degisim > 0) {
              giris += degisim;
            } else {
              cikis += -degisim;
            }
          }
          return {'giris': giris, 'cikis': cikis};
        });
  }

  Stream<Map<String, int>> getAylikGirisCikis() {
    final DateTime now = DateTime.now();
    final DateTime startOfMonth = DateTime(now.year, now.month, 1);
    return _hareketler
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
        )
        .snapshots()
        .map((snapshot) {
          int giris = 0;
          int cikis = 0;
          for (final doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final int degisim = (data['degisim'] as int?) ?? 0;
            if (degisim > 0) {
              giris += degisim;
            } else {
              cikis += -degisim;
            }
          }
          return {'giris': giris, 'cikis': cikis};
        });
  }

  Stream<List<Map<String, dynamic>>> getSonHareketler({int limit = 50}) {
    return _hareketler
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'id': doc.id,
              'itemId': data['itemId'] ?? '',
              'ad': data['ad'] ?? '',
              'degisim': (data['degisim'] as int?) ?? 0,
              'tur': data['tur'] ?? (data['degisim'] >= 0 ? 'giris' : 'cikis'),
              'kaynak': data['kaynak'] ?? '',
              'timestamp': (data['timestamp'] is Timestamp)
                  ? (data['timestamp'] as Timestamp).toDate()
                  : DateTime.now(),
            };
          }).toList(),
        );
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

  // Eksik isteği güncelleme ve envanteri artırma
  Future<void> updateEksikIstekDurum(
    String istekId,
    String durum, {
    Map<String, int>? eksikUrunler,
  }) async {
    await _eksikIstekler.doc(istekId).update({'durum': durum});
    if (durum == 'onaylandı' && eksikUrunler != null) {
      for (var entry in eksikUrunler.entries) {
        final itemSnapshot = await _envanter.doc(entry.key).get();
        if (itemSnapshot.exists) {
          final currentMiktar =
              (itemSnapshot.data() as Map<String, dynamic>)['miktar'] as int;
          await updateEnvanterMiktar(entry.key, currentMiktar + entry.value);
        } else {
          await addEnvanterItem(
            EnvanterItem(
              id: entry.key,
              ad: entry.key.replaceAll('_', ' ').toUpperCase(),
              miktar: entry.value,
            ),
          );
        }
      }
      await updateIhtiyacDurum(istekId, 'beklemede');
    }
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _users.doc(uid).update(data);
  }

  Stream<Map<String, int>> getUserRoleCounts() {
    return _users.snapshots().map((snapshot) {
      int depremzede = 0;
      int gonullu = 0;
      int kurum = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final String role = (data['role'] as String?)?.toLowerCase() ?? '';
        if (role == 'depremzede') depremzede++;
        if (role == 'gonullu') gonullu++;
        if (role == 'kurum') kurum++;
      }
      return {'depremzede': depremzede, 'gonullu': gonullu, 'kurum': kurum};
    });
  }
}
