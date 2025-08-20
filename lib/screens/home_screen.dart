import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import 'ihtiyac_bildirim_screen.dart';

class HomeScreen extends StatelessWidget {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: _authService.user,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData) {
          return Scaffold(body: Center(child: Text('Kullanıcı bulunamadı')));
        }
        final user = snapshot.data!;
        return Scaffold(
          appBar: AppBar(
            title: Text('Deprem Yardım Uygulaması'),
            actions: [
              IconButton(
                icon: Icon(Icons.logout),
                onPressed: () async {
                  await _authService.signOut();
                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),
            ],
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Hoş Geldiniz, ${user.email}!'),
                Text('Rolünüz: ${user.role}'),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: user.role == 'depremzede'
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => IhtiyacBildirimScreen(),
                            ),
                          );
                        }
                      : null,
                  child: Text('İhtiyaç Bildir'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
