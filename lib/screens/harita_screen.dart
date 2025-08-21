import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/ihtiyac.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import 'teklif_ekle_screen.dart';
import '../models/user.dart';

class HaritaScreen extends StatefulWidget {
  @override
  _HaritaScreenState createState() => _HaritaScreenState();
}

class _HaritaScreenState extends State<HaritaScreen>
    with AutomaticKeepAliveClientMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  GoogleMapController? _mapController;
  LatLng? _userLocation;
  final Set<Marker> _markers = {};
  String? _selectedKategori = 'Tümü';
  bool _isMapInitialized = false;

  @override
  bool get wantKeepAlive => true; // Harita ekranını canlı tutar

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    if (_isMapInitialized) return;
    await _getUserLocation();
    setState(() {
      _isMapInitialized = true;
    });
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Konum servisleri kapalı')));
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Konum izni reddedildi')));
          return;
        }
      }
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      ); // Daha hızlı konum alma
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      });
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_userLocation!, 13.0),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Konum alınamadı: $e')));
    }
  }

  Future<void> _launchMapDirections(
    double lat,
    double lng,
    String label,
  ) async {
    final url = 'geo:$lat,$lng?q=$lat,$lng($label)';
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalNonBrowserApplication);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Harita uygulaması açılamadı')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin için gerekli
    return StreamBuilder<AppUser?>(
      stream: _authService.user,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        final user = snapshot.data!;
        return Scaffold(
          appBar: AppBar(
            title: Text('İhtiyaç Haritası'),
            actions: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: DropdownButton<String>(
                  value: _selectedKategori,
                  items: ['Tümü', 'Gıda', 'Su', 'Barınma', 'Sağlık'].map((
                    kategori,
                  ) {
                    return DropdownMenuItem(
                      value: kategori,
                      child: Text(kategori),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedKategori = value;
                    });
                  },
                ),
              ),
            ],
          ),
          body: _userLocation == null || !_isMapInitialized
              ? Center(child: CircularProgressIndicator())
              : StreamBuilder<List<Ihtiyac>>(
                  stream: _firestoreService.getIhtiyaclar(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Veri yükleme hatası: ${snapshot.error}'),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text('İhtiyaç bulunamadı'));
                    }

                    final ihtiyaclar = snapshot.data!;
                    _markers.clear();
                    _markers.addAll(
                      ihtiyaclar
                          .where((ihtiyac) {
                            return _selectedKategori == 'Tümü' ||
                                ihtiyac.kategori == _selectedKategori;
                          })
                          .map((ihtiyac) {
                            return Marker(
                              markerId: MarkerId(ihtiyac.id),
                              position: LatLng(
                                ihtiyac.latitude,
                                ihtiyac.longitude,
                              ),
                              infoWindow: InfoWindow(
                                title: ihtiyac.kategori,
                                snippet:
                                    '${ihtiyac.aciklama}\nDurum: ${ihtiyac.durum}',
                                onTap: () {
                                  if (user.role == 'gonullu') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TeklifEkleScreen(
                                          ihtiyacId: ihtiyac.id,
                                        ),
                                      ),
                                    );
                                  } else {
                                    _launchMapDirections(
                                      ihtiyac.latitude,
                                      ihtiyac.longitude,
                                      ihtiyac.kategori,
                                    );
                                  }
                                },
                              ),
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                ihtiyac.kategori == 'Gıda'
                                    ? BitmapDescriptor.hueRed
                                    : ihtiyac.kategori == 'Su'
                                    ? BitmapDescriptor.hueBlue
                                    : ihtiyac.kategori == 'Barınma'
                                    ? BitmapDescriptor.hueGreen
                                    : BitmapDescriptor.hueYellow,
                              ),
                            );
                          })
                          .toSet(),
                    );

                    return GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _userLocation!,
                        zoom: 13.0,
                      ),
                      markers: _markers,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      mapType: MapType.normal, // Daha hafif bir harita türü
                      liteModeEnabled:
                          false, // Lite mod devre dışı, tam performans
                      onMapCreated: (GoogleMapController controller) {
                        _mapController = controller;
                      },
                      onTap: (LatLng position) {
                        FocusScope.of(context).unfocus();
                      },
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: _getUserLocation,
            child: Icon(Icons.my_location),
            tooltip: 'Konumuma Git',
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
