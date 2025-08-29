import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/ihtiyac.dart';
import '../models/envanter.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../models/user.dart';

class IhtiyacBildirimScreen extends StatefulWidget {
  @override
  _IhtiyacBildirimScreenState createState() => _IhtiyacBildirimScreenState();
}

class _IhtiyacBildirimScreenState extends State<IhtiyacBildirimScreen>
    with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final TextEditingController _isimController = TextEditingController();
  final TextEditingController _soyisimController = TextEditingController();
  final TextEditingController _adresTarifiController = TextEditingController();
  final TextEditingController _notController = TextEditingController();
  Map<String, int> _secilenUrunler = {};
  bool _isLoading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await _authService.user.first;
    if (user != null) {
      setState(() {
        _isimController.text = user.isim;
        _soyisimController.text = user.soyisim;
        _adresTarifiController.text = user.adres ?? '';
      });
    }
  }

  Future<void> _submitIhtiyac() async {
    if (_formKey.currentState!.validate() && _secilenUrunler.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
        );
        final now = DateTime.now();
        Ihtiyac ihtiyac = Ihtiyac(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: FirebaseAuth.instance.currentUser!.uid,
          urunler: _secilenUrunler,
          isim: _isimController.text,
          soyisim: _soyisimController.text,
          adresTarifi: _adresTarifiController.text.isEmpty
              ? ''
              : _adresTarifiController.text,
          not: _notController.text,
          latitude: position.latitude,
          longitude: position.longitude,
          timestamp: now,
        );
        await _firestoreService.addIhtiyac(ihtiyac);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('İhtiyaç bildirildi')));
        setState(() {
          _secilenUrunler = {};
          _notController.clear();
          _adresTarifiController.clear();
        });
        _formKey.currentState!.reset();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      } finally {
        setState(() => _isLoading = false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lütfen en az bir ürün seçin ve gerekli alanları doldurun',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final now = DateTime.now();
    final tarih = DateFormat('dd/MM/yyyy').format(now);
    final saat = DateFormat('HH:mm').format(now);

    return Scaffold(
      appBar: AppBar(title: Text('İhtiyaç Bildir')),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _isimController,
                  decoration: InputDecoration(
                    labelText: 'İsim',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'İsim gerekli';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _soyisimController,
                  decoration: InputDecoration(
                    labelText: 'Soyisim',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Soyisim gerekli';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _adresTarifiController,
                  decoration: InputDecoration(
                    labelText: 'Adres Tarifi (İsteğe bağlı)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _notController,
                  decoration: InputDecoration(
                    labelText: 'Not (İsteğe bağlı)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                Text('Tarih: $tarih'),
                SizedBox(height: 8),
                Text('Saat: $saat'),
                SizedBox(height: 16),
                Text(
                  'Ürün Seçimi',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                StreamBuilder<List<EnvanterItem>>(
                  stream: _firestoreService.getEnvanter(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Hata: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text('Depoda ürün bulunamadı'));
                    }

                    final envanter = snapshot.data!;
                    return Column(
                      children: envanter.map((item) {
                        return ListTile(
                          title: Text(item.ad),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.remove),
                                onPressed: () {
                                  setState(() {
                                    if (_secilenUrunler.containsKey(item.id)) {
                                      if (_secilenUrunler[item.id]! > 0) {
                                        _secilenUrunler[item.id] =
                                            _secilenUrunler[item.id]! - 1;
                                        if (_secilenUrunler[item.id] == 0) {
                                          _secilenUrunler.remove(item.id);
                                        }
                                      }
                                    }
                                  });
                                },
                              ),
                              Text(_secilenUrunler[item.id]?.toString() ?? '0'),
                              IconButton(
                                icon: Icon(Icons.add),
                                onPressed: () {
                                  setState(() {
                                    _secilenUrunler[item.id] =
                                        (_secilenUrunler[item.id] ?? 0) + 1;
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitIhtiyac,
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('İhtiyacı Bildir'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _isimController.dispose();
    _soyisimController.dispose();
    _adresTarifiController.dispose();
    _notController.dispose();
    super.dispose();
  }
}
