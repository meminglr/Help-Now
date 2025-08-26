import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  @override
  bool get wantKeepAlive => true;

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Envanter yetersiz: ${eksikUrunler.entries.map((e) => "${e.key}: ${e.value} adet").join(", ")}',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }

  Future<void> _reddetIhtiyac(Ihtiyac ihtiyac) async {
    try {
      await _firestoreService.updateIhtiyacDurum(ihtiyac.id, 'reddedildi');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('İhtiyaç reddedildi')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }

  Future<void> _kurumdanIste(Ihtiyac ihtiyac) async {
    try {
      final envanterSnapshot = await _firestoreService.getEnvanter().first;
      Map<String, int> eksikUrunler = {};

      for (var entry in ihtiyac.urunler.entries) {
        final item = envanterSnapshot.firstWhere(
          (e) => e.id == entry.key,
          orElse: () =>
              EnvanterItem(id: entry.key, ad: 'Bilinmeyen', miktar: 0),
        );
        if (item.miktar < entry.value) {
          eksikUrunler[entry.key] = entry.value - item.miktar;
        }
      }

      if (eksikUrunler.isNotEmpty) {
        await _firestoreService.addEksikIstek(ihtiyac.id, eksikUrunler);
        await _firestoreService.updateIhtiyacDurum(ihtiyac.id, 'yetersiz');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Kurumdan istek gönderildi')));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Eksik ürün yok')));
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
    return Scaffold(
      appBar: AppBar(title: Text('İhtiyaç Onaylama')),
      body: StreamBuilder<List<Ihtiyac>>(
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
              .where((i) => i.durum == 'beklemede' || i.durum == 'yetersiz')
              .toList();
          return ListView.builder(
            itemCount: ihtiyaclar.length,
            itemBuilder: (context, index) {
              final ihtiyac = ihtiyaclar[index];
              return ListTile(
                title: Text(
                  'İhtiyaç #${ihtiyac.id} (${ihtiyac.isim} ${ihtiyac.soyisim})',
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...ihtiyac.urunler.entries.map(
                      (e) => Text('${e.key}: ${e.value} adet'),
                    ),
                    Text('Adres: ${ihtiyac.adresTarifi}'),
                    if (ihtiyac.not.isNotEmpty) Text('Not: ${ihtiyac.not}'),
                    Text(
                      'Tarih: ${DateFormat('dd/MM/yyyy').format(ihtiyac.timestamp)}',
                    ),
                    Text(
                      'Saat: ${DateFormat('HH:mm').format(ihtiyac.timestamp)}',
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.check, color: Colors.green),
                      onPressed: () => _onayIhtiyac(ihtiyac),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.red),
                      onPressed: () => _reddetIhtiyac(ihtiyac),
                    ),
                    IconButton(
                      icon: Icon(Icons.send, color: Colors.blue),
                      onPressed: () => _kurumdanIste(ihtiyac),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
