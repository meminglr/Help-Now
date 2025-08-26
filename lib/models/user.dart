import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String role;
  final String isim;
  final String soyisim;
  final String? adres;

  AppUser({
    required this.uid,
    required this.email,
    required this.role,
    required this.isim,
    required this.soyisim,
    this.adres,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
      'isim': isim,
      'soyisim': soyisim,
      'adres': adres,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map, String uid) {
    return AppUser(
      uid: uid,
      email: map['email'] ?? '',
      role: map['role'] ?? 'depremzede',
      isim: map['isim'] ?? '',
      soyisim: map['soyisim'] ?? '',
      adres: map['adres'],
    );
  }
}
