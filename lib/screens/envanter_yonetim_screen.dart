import 'package:flutter/material.dart';
import '../models/envanter.dart';
import '../services/firestore_service.dart';

class EnvanterYonetimScreen extends StatefulWidget {
  @override
  _EnvanterYonetimScreenState createState() => _EnvanterYonetimScreenState();
}

class _EnvanterYonetimScreenState extends State<EnvanterYonetimScreen>
    with AutomaticKeepAliveClientMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _urunAdiController = TextEditingController();
  final TextEditingController _urunMiktarController = TextEditingController();
  int _totalStok = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _calculateTotalStok();
  }

  Future<void> _calculateTotalStok() async {
    final envanter = await _firestoreService.getEnvanter().first;
    final total = envanter.fold<int>(0, (sum, item) => sum + item.miktar);
    setState(() {
      _totalStok = total;
    });
  }

  Future<void> _addOrUpdateUrun() async {
    if (_urunAdiController.text.isEmpty || _urunMiktarController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ürün adı ve miktar girin')));
      return;
    }

    try {
      final urunId = _urunAdiController.text.toLowerCase().replaceAll(' ', '_');
      final miktar = int.parse(_urunMiktarController.text);
      final mevcutUrun = await _firestoreService.getEnvanter().first.then(
        (list) => list.firstWhere(
          (item) => item.id == urunId,
          orElse: () => EnvanterItem(id: '', ad: '', miktar: 0),
        ),
      );

      if (mevcutUrun.id.isEmpty) {
        await _firestoreService.addEnvanterItem(
          EnvanterItem(id: urunId, ad: _urunAdiController.text, miktar: miktar),
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Yeni ürün eklendi')));
      } else {
        await _firestoreService.updateEnvanterMiktar(urunId, miktar);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ürün miktarı güncellendi')));
      }
      _calculateTotalStok();
      _urunAdiController.clear();
      _urunMiktarController.clear();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(title: Text('Envanter Yönetimi')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Envanter Doluluk Durumu
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Envanter Doluluk Durumu',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  SizedBox(height: 8),
                  Text('Toplam Stok: $_totalStok birim'),
                  SizedBox(height: 16),
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
                        return Center(
                          child: Text('Envanterde ürün bulunamadı'),
                        );
                      }

                      final envanter = snapshot.data!;
                      return Column(
                        children: envanter.map((item) {
                          return ListTile(
                            title: Text('${item.ad} (Stok: ${item.miktar})'),
                            trailing: IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () async {
                                try {
                                  await _firestoreService.updateEnvanterMiktar(
                                    item.id,
                                    0,
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${item.ad} kaldırıldı'),
                                    ),
                                  );
                                  _calculateTotalStok();
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Hata: $e')),
                                  );
                                }
                              },
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
            // Yeni Ürün Ekleme
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Yeni Ürün Ekle / Güncelle',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: _urunAdiController,
                    decoration: InputDecoration(labelText: 'Ürün Adı'),
                  ),
                  TextField(
                    controller: _urunMiktarController,
                    decoration: InputDecoration(labelText: 'Miktar'),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _addOrUpdateUrun,
                    child: Text('Ekle/Güncelle'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _urunAdiController.dispose();
    _urunMiktarController.dispose();
    super.dispose();
  }
}
