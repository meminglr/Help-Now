import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/ihtiyac.dart';
import '../models/envanter.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('İhtiyaç Bildir'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _isimController,
                  decoration: const InputDecoration(
                    labelText: 'İsim',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'İsim gerekli';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _soyisimController,
                  decoration: const InputDecoration(
                    labelText: 'Soyisim',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Soyisim gerekli';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _adresTarifiController,
                  decoration: const InputDecoration(
                    labelText: 'Adres Tarifi (İsteğe bağlı)',
                    prefixIcon: Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notController,
                  decoration: const InputDecoration(
                    labelText: 'Not (İsteğe bağlı)',
                    prefixIcon: Icon(Icons.note_outlined),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Text(
                  'Tarih: $tarih',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Saat: $saat',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  'Ürün Seçimi',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                StreamBuilder<List<EnvanterItem>>(
                  stream: _firestoreService.getEnvanter(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.blue,
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Hata: ${snapshot.error}',
                          style: TextStyle(color: Colors.black54),
                        ),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text(
                          'Depoda ürün bulunamadı',
                          style: TextStyle(color: Colors.black54),
                        ),
                      );
                    }

                    final envanter = snapshot.data!;
                    return Column(
                      children: envanter.map((item) {
                        return Card(
                          elevation: 0,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.ad,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () {
                                    setState(() {
                                      if (_secilenUrunler.containsKey(
                                        item.id,
                                      )) {
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
                                Text(
                                  _secilenUrunler[item.id]?.toString() ?? '0',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () {
                                    setState(() {
                                      _secilenUrunler[item.id] =
                                          (_secilenUrunler[item.id] ?? 0) + 1;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isLoading ? null : _submitIhtiyac,
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'İhtiyacı Bildir',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
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
