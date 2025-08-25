import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ihtiyac.dart';
import '../models/envanter.dart';
import '../services/firestore_service.dart';

class IhtiyacBildirimScreen extends StatefulWidget {
  @override
  _IhtiyacBildirimScreenState createState() => _IhtiyacBildirimScreenState();
}

class _IhtiyacBildirimScreenState extends State<IhtiyacBildirimScreen>
    with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  Map<String, int> _secilenUrunler = {};
  bool _isLoading = false;

  @override
  bool get wantKeepAlive => true;

  Future<void> _submitIhtiyac() async {
    if (_formKey.currentState!.validate() && _secilenUrunler.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
        );
        Ihtiyac ihtiyac = Ihtiyac(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: FirebaseAuth.instance.currentUser!.uid,
          urunler: _secilenUrunler,
          latitude: position.latitude,
          longitude: position.longitude,
          timestamp: DateTime.now(),
        );
        await _firestoreService.addIhtiyac(ihtiyac);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('İhtiyaç bildirildi')));
        setState(() {
          _secilenUrunler = {};
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lütfen en az bir ürün seçin')));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(title: Text('İhtiyaç Bildir')),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
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
                      return Center(child: Text('Envanterde ürün bulunamadı'));
                    }

                    final envanter = snapshot.data!;
                    return Column(
                      children: envanter.map((item) {
                        return ListTile(
                          title: Text('${item.ad} (Stok: ${item.miktar})'),
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
                                  if (item.miktar >
                                      (_secilenUrunler[item.id] ?? 0)) {
                                    setState(() {
                                      _secilenUrunler[item.id] =
                                          (_secilenUrunler[item.id] ?? 0) + 1;
                                    });
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${item.ad} için yeterli stok yok',
                                        ),
                                      ),
                                    );
                                  }
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
}
