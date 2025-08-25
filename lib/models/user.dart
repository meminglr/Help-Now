class AppUser {
  final String uid;
  final String email;
  final String role;
  final String? name;
  final String? phone;

  AppUser({
    required this.uid,
    required this.email,
    required this.role,
    this.name,
    this.phone,
  });
}
