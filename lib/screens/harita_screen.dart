import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/ihtiyac.dart';
import '../services/firestore_service.dart';

class HaritaScreen extends StatefulWidget {
  @override
  _HaritaScreenState createState() => _HaritaScreenState();
}

class _HaritaScreenState extends State<HaritaScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  GoogleMapController? _mapController;
  LatLng? _userLocation;
  final Set<Marker> _markers = {};
  String? _selectedKategori = 'Tümü';

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Konum servisleri kapalı')),
        );
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Konum izni reddedildi')),
          );
          return;
        }
      }
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      });
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_userLocation!, 13.0),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Konum alınamadı: $e')),
      );
    }
  }

  Future<void> _launchMapDirections(double lat, double lng, String label) async {
    final url = 'geo:$lat,$lng?q=$lat,$lng($label)';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Harita uygulaması açılamadı')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('İhtiyaç Haritası'),
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButton<String>(
              value: _selectedKategori,
              items: ['Tümü', 'Gıda', 'Su', 'Barınma', 'Sağlık'].map((kategori) {
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
      body: _userLocation == null
          ? Center(child: CircularProgressIndicator())
          : StreamBuilder<List<Ihtiyac>>(
              stream: _firestoreService.getIhtiyaclar(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Veri yükleme hatası: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('İhtiyaç bulunamadı'));
                }

                final ihtiyaclar = snapshot.data!;
                _markers.clear();
                _markers.addAll(ihtiyaclar.where((ihtiyac) {
                  return _selectedKategori == 'Tümü' ||
                      ihtiyac.kategori == _selectedKategori;
                }).map((ihtiyac) {
                  return Marker(
                    markerId: MarkerId(ihtiyac.id),
                    position: LatLng(ihtiyac.latitude, ihtiyac.longitude),
                    infoWindow: InfoWindow(
                      title: ihtiyac.kategori,
                      snippet: ihtiyac.aciklama,
                      onTap: () {
                        _launchMapDirections(
                          ihtiyac.latitude,
                          ihtiyac.longitude,
                          ihtiyac.kategori,
                        );
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
                }).toSet());

                return GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _userLocation!,
                    zoom: 13.0,
                  ),
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
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
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}