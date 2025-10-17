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
              'Depo yetersiz: ${eksikUrunler.entries.map((e) => "${e.key}: ${e.value} adet").join(", ")}',
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('İhtiyaç Onaylama'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<List<EnvanterItem>>(
        stream: _firestoreService.getEnvanter(),
        builder: (context, envanterSnap) {
          if (envanterSnap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.blue,
              ),
            );
          }
          if (envanterSnap.hasError) {
            return Center(
              child: Text(
                'Hata: ${envanterSnap.error}',
                style: TextStyle(color: Colors.black54),
              ),
            );
          }
          final envanter = envanterSnap.data ?? const <EnvanterItem>[];

          return StreamBuilder<List<Ihtiyac>>(
            stream: _firestoreService.getIhtiyaclar(),
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
                    'İhtiyaç bulunamadı',
                    style: TextStyle(color: Colors.black54),
                  ),
                );
              }

              final ihtiyaclar = snapshot.data!
                  .where((i) => i.durum == 'beklemede' || i.durum == 'yetersiz')
                  .toList();
              return ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: ihtiyaclar.length,
                itemBuilder: (context, index) {
                  final ihtiyac = ihtiyaclar[index];

                  bool hasMissing = false;
                  for (var entry in ihtiyac.urunler.entries) {
                    final item = envanter.firstWhere(
                      (e) => e.id == entry.key,
                      orElse: () => EnvanterItem(
                        id: entry.key,
                        ad: 'Bilinmeyen',
                        miktar: 0,
                      ),
                    );
                    if (item.miktar < entry.value) {
                      hasMissing = true;
                      break;
                    }
                  }

                  return ihtiyacList(ihtiyac, context, hasMissing);
                },
              );
            },
          );
        },
      ),
    );
  }

  SizedBox ihtiyacList(Ihtiyac ihtiyac, BuildContext context, bool hasMissing) {
    return SizedBox(
      height: 200,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        child: Row(
          spacing: 5,
          children: [
            Expanded(
              flex: 4,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(20),
                    right: Radius.circular(5),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'İhtiyaç (${ihtiyac.isim} ${ihtiyac.soyisim})',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      ...ihtiyac.urunler.entries.map(
                        (e) => Text(
                          '${e.key}: ${e.value} adet',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Adres: ${ihtiyac.adresTarifi}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (ihtiyac.not.isNotEmpty)
                        Text(
                          'Not: ${ihtiyac.not}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            'Tarih: ${DateFormat('dd/MM/yyyy').format(ihtiyac.timestamp)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Saat: ${DateFormat('HH:mm').format(ihtiyac.timestamp)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _onayIhtiyac(ihtiyac),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(20),
                            topLeft: Radius.circular(5),
                          ),
                        ),
                        child: Row(
                          spacing: 5,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check,
                              size: 18,
                              color: Colors.green[100],
                            ),
                            Text(
                              'Onayla',
                              style: TextStyle(color: Colors.green[100]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _reddetIhtiyac(ihtiyac),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.only(
                            bottomRight: hasMissing
                                ? Radius.circular(0)
                                : Radius.circular(20),
                            bottomLeft: hasMissing
                                ? Radius.circular(0)
                                : Radius.circular(5),
                          ),
                        ),
                        child: Row(
                          spacing: 5,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.close, size: 18, color: Colors.red[100]),
                            Text(
                              'Reddet',
                              style: TextStyle(color: Colors.red[100]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  if (hasMissing)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _kurumdanIste(ihtiyac),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.only(
                              bottomRight: Radius.circular(20),
                              bottomLeft: Radius.circular(8),
                            ),
                          ),
                          child: Row(
                            spacing: 5,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.send,
                                size: 18,
                                color: Colors.blue[100],
                              ),
                              Text(
                                'Bildir',
                                style: TextStyle(color: Colors.blue[100]),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
