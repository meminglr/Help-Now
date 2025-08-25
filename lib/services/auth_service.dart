import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollectionReference _users = FirebaseFirestore.instance.collection(
    'users',
  );

  // Kullanıcıyı AppUser modeline dönüştür
  AppUser? _userFromFirebaseUser(User? user) {
    if (user == null) return null;
    return AppUser(uid: user.uid, email: user.email ?? '', role: '');
  }

  // Kullanıcı stream’i
  Stream<AppUser?> get user {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      final doc = await _users.doc(firebaseUser.uid).get();
      if (!doc.exists) return null;
      final data = doc.data() as Map<String, dynamic>;
      return AppUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        role: data['role'] ?? '',
        name: data['name'],
        phone: data['phone'],
      );
    });
  }

  // E-posta ve şifre ile giriş
  Future<AppUser?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      if (result.user == null) return null;
      final doc = await _users.doc(result.user!.uid).get();
      if (!doc.exists) {
        throw Exception('Kullanıcı verisi bulunamadı');
      }
      final data = doc.data() as Map<String, dynamic>;
      return AppUser(
        uid: result.user!.uid,
        email: result.user!.email ?? '',
        role: data['role'] ?? '',
        name: data['name'],
        phone: data['phone'],
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw Exception('Kullanıcı bulunamadı');
        case 'wrong-password':
          throw Exception('Yanlış şifre');
        case 'invalid-email':
          throw Exception('Geçersiz e-posta adresi');
        case 'user-disabled':
          throw Exception('Kullanıcı hesabı devre dışı');
        default:
          throw Exception('Giriş hatası: ${e.message}');
      }
    } catch (e) {
      throw Exception('Bilinmeyen hata: $e');
    }
  }

  // Kayıt olma
  Future<AppUser?> signUp(String email, String password, String role) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      if (result.user == null) return null;
      await _users.doc(result.user!.uid).set({
        'email': email,
        'role': role,
        'name': '',
        'phone': '',
      });
      return AppUser(
        uid: result.user!.uid,
        email: result.user!.email ?? '',
        role: role,
        name: '',
        phone: '',
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          throw Exception('Bu e-posta zaten kullanımda');
        case 'invalid-email':
          throw Exception('Geçersiz e-posta adresi');
        case 'weak-password':
          throw Exception('Zayıf şifre, daha güçlü bir şifre seçin');
        default:
          throw Exception('Kayıt hatası: ${e.message}');
      }
    } catch (e) {
      throw Exception('Bilinmeyen hata: $e');
    }
  }

  // Çıkış yap
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
