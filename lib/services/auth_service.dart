import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import 'package:rxdart/rxdart.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollectionReference _users = FirebaseFirestore.instance.collection(
    'users',
  );
  final BehaviorSubject<AppUser?> _userSubject = BehaviorSubject<AppUser?>();

  Stream<AppUser?> get user => _userSubject.stream;

  AuthService() {
    _auth.authStateChanges().listen((User? firebaseUser) async {
      if (firebaseUser == null) {
        _userSubject.add(null);
      } else {
        final doc = await _users.doc(firebaseUser.uid).get();
        if (doc.exists) {
          _userSubject.add(
            AppUser.fromMap(
              doc.data() as Map<String, dynamic>,
              firebaseUser.uid,
            ),
          );
        }
      }
    });
  }

  Future<User?> signUp(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> saveUserData(AppUser user) async {
    await _users.doc(user.uid).set(user.toMap());
    _userSubject.add(user);
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _users.doc(uid).update(data);
    final doc = await _users.doc(uid).get();
    if (doc.exists) {
      _userSubject.add(
        AppUser.fromMap(doc.data() as Map<String, dynamic>, uid),
      );
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _userSubject.add(null);
  }

  void dispose() {
    _userSubject.close();
  }
}
