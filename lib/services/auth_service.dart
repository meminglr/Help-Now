import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Kullanıcı durumunu dinleme
  Stream<AppUser?> get user {
    return _auth.authStateChanges().asyncMap((User? user) async {
      if (user == null) return null;
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();
      return AppUser.fromMap(doc.data() as Map<String, dynamic>);
    });
  }

  // E-posta ile kayıt
  Future<AppUser?> registerWithEmail(
    String email,
    String password,
    String role,
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? firebaseUser = result.user;

      if (firebaseUser != null) {
        // Firestore’a kullanıcıyı kaydet
        AppUser appUser = AppUser(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          role: role,
        );
        await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .set(appUser.toMap());
        return appUser;
      }
      return null;
    } catch (e) {
      print('Kayıt hatası: $e');
      return null;
    }
  }

  // E-posta ile giriş
  Future<AppUser?> loginWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? firebaseUser = result.user;

      if (firebaseUser != null) {
        DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .get();
        return AppUser.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Giriş hatası: $e');
      return null;
    }
  }

  // Çıkış yap
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
