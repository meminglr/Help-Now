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

                  return Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'İhtiyaç #${ihtiyac.id} (${ihtiyac.isim} ${ihtiyac.soyisim})',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                ...ihtiyac.urunler.entries.map(
                                  (e) => Text(
                                    '${e.key}: ${e.value} adet',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
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
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Text(
                                      'Tarih: ${DateFormat('dd/MM/yyyy').format(ihtiyac.timestamp)}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Saat: ${DateFormat('HH:mm').format(ihtiyac.timestamp)}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 160),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    minimumSize: const Size(0, 40),
                                  ),
                                  icon: const Icon(Icons.check, size: 18),
                                  label: const Text('Onayla'),
                                  onPressed: () => _onayIhtiyac(ihtiyac),
                                ),
                                const SizedBox(height: 8),
                                FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    minimumSize: const Size(0, 40),
                                  ),
                                  icon: const Icon(Icons.close, size: 18),
                                  label: const Text('Reddet'),
                                  onPressed: () => _reddetIhtiyac(ihtiyac),
                                ),
                                const SizedBox(height: 8),
                                if (hasMissing)
                                  FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      minimumSize: const Size(0, 40),
                                    ),
                                    icon: const Icon(Icons.send, size: 18),
                                    label: const Text('Kurumdan iste'),
                                    onPressed: () => _kurumdanIste(ihtiyac),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
