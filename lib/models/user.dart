class AppUser {
  final String uid;
  final String email;
  final String role; // "depremzede", "gonullu", "kurum"

  AppUser({required this.uid, required this.email, required this.role});

  // Firestore’dan veri çekmek için
  factory AppUser.fromMap(Map<String, dynamic> data) {
    return AppUser(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'depremzede',
    );
  }

  // Firestore’a veri kaydetmek için
  Map<String, dynamic> toMap() {
    return {'uid': uid, 'email': email, 'role': role};
  }
}
