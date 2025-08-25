import 'package:flutter/material.dart';
import '../models/ihtiyac.dart';
import '../models/envanter.dart';
import '../services/firestore_service.dart';

class GonulluOnayScreen extends StatefulWidget {
  @override
  _GonulluOnayScreenState createState() => _GonulluOnayScreenState();
}

class _GonulluOnayScreenState extends State<GonulluOnayScreen>
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

  Future<void> _onayIhtiyac(Ihtiyac ihtiyac) async {
    try {
      final envanterSnapshot = await _firestoreService.getEnvanter().first;
      bool yeterliStok = true;
      Map<String, int> eksikUrunler = {};

      for (var entry in ihtiyac.urunler.entries) {
        final item = envanterSnapshot.firstWhere(
          (e) => e.id == entry.key,
          orElse: () =>
              EnvanterItem(id: entry.key, ad: 'Bilinmeyen', miktar: 0),
        );
        if (item.miktar < entry.value) {
          yeterliStok = false;
          eksikUrunler[entry.key] = entry.value - item.miktar;
        }
      }

      if (yeterliStok) {
        for (var entry in ihtiyac.urunler.entries) {
          final item = envanterSnapshot.firstWhere((e) => e.id == entry.key);
          await _firestoreService.updateEnvanterMiktar(
            entry.key,
            item.miktar - entry.value,
          );
        }
        await _firestoreService.updateIhtiyacDurum(ihtiyac.id, 'onaylandı');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('İhtiyaç onaylandı')));
      } else {
        await _firestoreService.addEksikIstek(ihtiyac.id, eksikUrunler);
        await _firestoreService.updateIhtiyacDurum(ihtiyac.id, 'yetersiz');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Envanter yetersiz, kurumlara bildirildi')),
        );
      }
      _calculateTotalStok();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
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
        // Yeni ürün ekle
        await _firestoreService.addEnvanterItem(
          EnvanterItem(id: urunId, ad: _urunAdiController.text, miktar: miktar),
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Yeni ürün eklendi')));
      } else {
        // Mevcut ürünü güncelle
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
      appBar: AppBar(title: Text('Gönüllü Yönetim')),
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
            // İhtiyaç Onaylama
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'İhtiyaç Onaylama',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  SizedBox(height: 8),
                  StreamBuilder<List<Ihtiyac>>(
                    stream: _firestoreService.getIhtiyaclar(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Hata: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(child: Text('İhtiyaç bulunamadı'));
                      }

                      final ihtiyaclar = snapshot.data!
                          .where(
                            (i) =>
                                i.durum == 'beklemede' || i.durum == 'yetersiz',
                          )
                          .toList();
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: ihtiyaclar.length,
                        itemBuilder: (context, index) {
                          final ihtiyac = ihtiyaclar[index];
                          return ListTile(
                            title: Text('İhtiyaç #${ihtiyac.id}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: ihtiyac.urunler.entries
                                  .map((e) => Text('${e.key}: ${e.value} adet'))
                                  .toList(),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.check),
                                  onPressed: () => _onayIhtiyac(ihtiyac),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
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
