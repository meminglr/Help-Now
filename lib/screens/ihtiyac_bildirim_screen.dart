import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ihtiyac.dart';
import '../services/firestore_service.dart';

class IhtiyacBildirimScreen extends StatefulWidget {
  @override
  _IhtiyacBildirimScreenState createState() => _IhtiyacBildirimScreenState();
}

class _IhtiyacBildirimScreenState extends State<IhtiyacBildirimScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _kategori;
  String _aciklama = '';
  bool _isLoading = false;
  final FirestoreService _firestoreService = FirestoreService();

  Future<Position> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return Future.error(
          'Konum servisleri kapalı. Lütfen cihazınızın konum ayarlarını kontrol edin.',
        );
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return Future.error(
            'Konum izni verilmedi. Lütfen uygulamaya konum izni verin.',
          );
        }
      }
      if (permission == LocationPermission.deniedForever) {
        return Future.error(
          'Konum izni kalıcı olarak reddedildi. Lütfen ayarlarınızı kontrol edin.',
        );
      }
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      return Future.error('Konum alınamadı: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('İhtiyaç Bildir')),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: 'Kategori'),
                    items: ['Gıda', 'Su', 'Barınma', 'Sağlık'].map((kategori) {
                      return DropdownMenuItem(
                        value: kategori,
                        child: Text(kategori),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _kategori = value;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Kategori seçin' : null,
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Açıklama'),
                    maxLines: 3,
                    onChanged: (value) {
                      _aciklama = value;
                    },
                    validator: (value) =>
                        value!.isEmpty ? 'Açıklama girin' : null,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            if (_formKey.currentState!.validate()) {
                              setState(() => _isLoading = true);
                              try {
                                Position position = await _getCurrentLocation();
                                Ihtiyac ihtiyac = Ihtiyac(
                                  id: DateTime.now().millisecondsSinceEpoch
                                      .toString(),
                                  userId:
                                      FirebaseAuth.instance.currentUser!.uid,
                                  kategori: _kategori!,
                                  aciklama: _aciklama,
                                  latitude: position.latitude,
                                  longitude: position.longitude,
                                  timestamp: DateTime.now(),
                                );
                                await _firestoreService.addIhtiyac(ihtiyac);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('İhtiyaç bildirildi!'),
                                  ),
                                );
                                Navigator.pop(context);
                              } catch (e) {
                                print('Hata: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Hata: $e')),
                                );
                              } finally {
                                setState(() => _isLoading = false);
                              }
                            }
                          },
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text('İhtiyacı Bildir'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
