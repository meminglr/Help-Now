import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../models/ihtiyac.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import 'gonullu_onay_screen.dart';

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
  String? _selectedDurum = 'Tümü';
  String _searchQuery = '';
  bool _isMapInitialized = false;

  @override
  bool get wantKeepAlive => true;

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
      );
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
        await launchUrl(uri, mode: LaunchMode.platformDefault);
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
    super.build(context);
    return StreamBuilder<AppUser?>(
      stream: _authService.user,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.blue,
            ),
          );
        }
        final user = snapshot.data!;
        if (user.role == 'depremzede') {
          return Scaffold(
            backgroundColor: Colors.white,
            body: const Center(
              child: Text(
                'Harita erişimi sadece gönüllü ve kurumlar için',
                style: TextStyle(color: Colors.black),
              ),
            ),
          );
        }
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text('İhtiyaç Haritası'),
            centerTitle: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedDurum,
                    items: const [
                      DropdownMenuItem(value: 'Tümü', child: Text('Tümü')),
                      DropdownMenuItem(
                        value: 'beklemede',
                        child: Text('Beklemede'),
                      ),
                      DropdownMenuItem(
                        value: 'onaylandı',
                        child: Text('Onaylandı'),
                      ),
                      DropdownMenuItem(
                        value: 'reddedildi',
                        child: Text('Reddedildi'),
                      ),
                      DropdownMenuItem(
                        value: 'yetersiz',
                        child: Text('Yetersiz'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedDurum = value;
                      });
                    },
                    style: Theme.of(context).textTheme.bodyMedium,
                    icon: const Icon(Icons.filter_alt_outlined),
                  ),
                ),
              ),
            ],
          ),
          body: _userLocation == null || !_isMapInitialized
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Harita yükleniyor...',
                        style: TextStyle(color: Colors.black),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    Column(
                      children: [
                        Expanded(
                          flex: 2,
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: _userLocation!,
                              zoom: 13.0,
                            ),
                            markers: _markers,
                            myLocationEnabled: true,
                            myLocationButtonEnabled: true,
                            mapType: MapType.normal,
                            onMapCreated: (GoogleMapController controller) {
                              _mapController = controller;
                            },
                            onTap: (LatLng position) {
                              FocusScope.of(context).unfocus();
                            },
                          ),
                        ),
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'İhtiyaç Ara (Ürün ID veya İsim)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.search),
                            ),
                            style: Theme.of(context).textTheme.bodyLarge,
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value.toLowerCase();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    DraggableScrollableSheet(
                      initialChildSize: 0.3,
                      minChildSize: 0.1,
                      maxChildSize: 0.9,
                      builder: (context, scrollController) {
                        return Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            boxShadow: [
                              BoxShadow(color: Colors.black12, blurRadius: 8),
                            ],
                          ),
                          child: StreamBuilder<List<Ihtiyac>>(
                            stream: _firestoreService.getIhtiyaclar(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
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
                                    'Veri yükleme hatası: ${snapshot.error}',
                                    style: TextStyle(color: Colors.black54),
                                  ),
                                );
                              }
                              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return const Center(
                                  child: Text(
                                    'İhtiyaç bulunamadı',
                                    style: TextStyle(color: Colors.black54),
                                  ),
                                );
                              }

                              final ihtiyaclar = snapshot.data!.where((
                                ihtiyac,
                              ) {
                                final matchesDurum =
                                    _selectedDurum == 'Tümü' ||
                                    ihtiyac.durum == _selectedDurum;
                                final matchesSearch =
                                    _searchQuery.isEmpty ||
                                    ihtiyac.urunler.keys.any(
                                      (key) => key.toLowerCase().contains(
                                        _searchQuery,
                                      ),
                                    ) ||
                                    ihtiyac.isim.toLowerCase().contains(
                                      _searchQuery,
                                    ) ||
                                    ihtiyac.soyisim.toLowerCase().contains(
                                      _searchQuery,
                                    );
                                return matchesDurum && matchesSearch;
                              }).toList();

                              _markers.clear();
                              _markers.addAll(
                                ihtiyaclar.map((ihtiyac) {
                                  return Marker(
                                    markerId: MarkerId(ihtiyac.id),
                                    position: LatLng(
                                      ihtiyac.latitude,
                                      ihtiyac.longitude,
                                    ),
                                    infoWindow: InfoWindow(
                                      title:
                                          'İhtiyaç #${ihtiyac.id} (${ihtiyac.isim} ${ihtiyac.soyisim})',
                                      snippet: [
                                        ...ihtiyac.urunler.entries.map(
                                          (e) => '${e.key}: ${e.value} adet',
                                        ),
                                        'Adres: ${ihtiyac.adresTarifi}',
                                        if (ihtiyac.not.isNotEmpty)
                                          'Not: ${ihtiyac.not}',
                                        'Durum: ${ihtiyac.durum}',
                                        'Tarih: ${DateFormat('dd/MM/yyyy').format(ihtiyac.timestamp)}',
                                        'Saat: ${DateFormat('HH:mm').format(ihtiyac.timestamp)}',
                                      ].join('\n'),
                                      onTap: () {
                                        if (user.role == 'gonullu') {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  GonulluOnayScreen(),
                                            ),
                                          );
                                        } else {
                                          _launchMapDirections(
                                            ihtiyac.latitude,
                                            ihtiyac.longitude,
                                            'İhtiyaç #${ihtiyac.id}',
                                          );
                                        }
                                      },
                                    ),
                                  );
                                }).toSet(),
                              );

                              return ListView.builder(
                                controller: scrollController,
                                itemCount: ihtiyaclar.length,
                                itemBuilder: (context, index) {
                                  final ihtiyac = ihtiyaclar[index];
                                  return Card(
                                    elevation: 0,
                                    color: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    child: ListTile(
                                      title: Text(
                                        'İhtiyaç #${ihtiyac.id} (${ihtiyac.isim} ${ihtiyac.soyisim})',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyLarge,
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          ...ihtiyac.urunler.entries.map(
                                            (e) => Text(
                                              '${e.key}: ${e.value} adet',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodyMedium,
                                            ),
                                          ),
                                          Text(
                                            'Adres: ${ihtiyac.adresTarifi}',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyMedium,
                                          ),
                                          if (ihtiyac.not.isNotEmpty)
                                            Text(
                                              'Not: ${ihtiyac.not}',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodyMedium,
                                            ),
                                          Text(
                                            'Tarih: ${DateFormat('dd/MM/yyyy').format(ihtiyac.timestamp)}',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          ),
                                          Text(
                                            'Saat: ${DateFormat('HH:mm').format(ihtiyac.timestamp)}',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(
                                          Icons.directions,
                                          color: Colors.blue,
                                        ),
                                        onPressed: () {
                                          _launchMapDirections(
                                            ihtiyac.latitude,
                                            ihtiyac.longitude,
                                            'İhtiyaç #${ihtiyac.id}',
                                          );
                                        },
                                      ),
                                      onTap: () {
                                        _mapController?.animateCamera(
                                          CameraUpdate.newLatLng(
                                            LatLng(
                                              ihtiyac.latitude,
                                              ihtiyac.longitude,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            onPressed: _getUserLocation,
            tooltip: 'Konumuma Git',
            child: const Icon(Icons.my_location),
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
