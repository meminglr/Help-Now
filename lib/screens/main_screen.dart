import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import 'home_screen.dart';
import 'ihtiyac_bildirim_screen.dart';
import 'harita_screen.dart';
import 'kurum_yonetim_screen.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final AuthService _authService = AuthService();
  int _selectedIndex = 0;
  AppUser? _user;
  List<Widget>? _screens;
  List<BottomNavigationBarItem>? _items;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _authService.user.first; // Stream’den bir kez veri al
      if (user == null) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      setState(() {
        _user = user;
        _screens = [
          HomeScreen(),
          if (user.role == 'depremzede') IhtiyacBildirimScreen(),
          HaritaScreen(),
          if (user.role == 'kurum') KurumYonetimScreen(),
        ];
        _items = [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ana Sayfa'),
          if (user.role == 'depremzede')
            BottomNavigationBarItem(
              icon: Icon(Icons.add_alert),
              label: 'İhtiyaç Bildir',
            ),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Harita'),
          if (user.role == 'kurum')
            BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings),
              label: 'Yönetim',
            ),
        ];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Kullanıcı yüklenemedi: $e')));
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _user == null || _screens == null || _items == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Yükleniyor...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens!),
      bottomNavigationBar: BottomNavigationBar(
        items: _items!,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type:
            BottomNavigationBarType.fixed, // Sekme animasyonlarını sabit tutar
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
