import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import 'home_screen.dart';
import 'ihtiyac_bildirim_screen.dart';
import 'harita_screen.dart';
import 'kurum_yonetim_screen.dart';
import 'profile_screen.dart';
import 'gonullu_onay_screen.dart';
import 'envanter_yonetim_screen.dart';

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
      final user = await _authService.user.first;
      if (user == null) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      setState(() {
        _user = user;
        _screens = [
          // HomeScreen'e bottom tab geçiş callback ve hedef indeksler geçilir
          HomeScreen(
            onNavigateToTab: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
          if (user.role == 'depremzede') IhtiyacBildirimScreen(),
          if (user.role != 'depremzede') HaritaScreen(),
          if (user.role == 'gonullu') GonulluOnayScreen(),
          if (user.role == 'gonullu') EnvanterYonetimScreen(),
          if (user.role == 'kurum') KurumYonetimScreen(),
          ProfileScreen(),
        ];
        _items = [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ana Sayfa'),
          if (user.role == 'depremzede')
            BottomNavigationBarItem(
              icon: Icon(Icons.add_alert),
              label: 'İhtiyaç Bildir',
            ),
          if (user.role != 'depremzede')
            BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Harita'),
          if (user.role == 'gonullu')
            BottomNavigationBarItem(
              icon: Icon(Icons.check_circle),
              label: 'Onaylama',
            ),
          if (user.role == 'gonullu')
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory),
              label: 'Envanter',
            ),
          if (user.role == 'kurum')
            BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings),
              label: 'Yönetim',
            ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ];
        // Gonullu sekme indekslerini hesapla ve HomeScreen'e yeniden kurulumla ilet
        if (user.role == 'gonullu') {
          final onayIndex = _screens!.indexWhere(
            (w) => w.runtimeType.toString() == 'GonulluOnayScreen',
          );
          final envanterIndex = _screens!.indexWhere(
            (w) => w.runtimeType.toString() == 'EnvanterYonetimScreen',
          );
          _screens![0] = HomeScreen(
            onNavigateToTab: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            gonulluOnayTabIndex: onayIndex >= 0 ? onayIndex : null,
            envanterTabIndex: envanterIndex >= 0 ? envanterIndex : null,
          );
        }
        // Kurum sekme indeksini hesapla ve HomeScreen'e ilet
        if (user.role == 'kurum') {
          final kurumIndex = _screens!.indexWhere(
            (w) => w.runtimeType.toString() == 'KurumYonetimScreen',
          );
          _screens![0] = HomeScreen(
            onNavigateToTab: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            kurumYonetimTabIndex: kurumIndex >= 0 ? kurumIndex : null,
          );
        }
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
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
