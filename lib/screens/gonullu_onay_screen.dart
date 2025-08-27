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
      body: StreamBuilder<List<EnvanterItem>>(
        stream: _firestoreService.getEnvanter(),
        builder: (context, envanterSnap) {
          if (envanterSnap.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (envanterSnap.hasError) {
            return Center(child: Text('Hata: ${envanterSnap.error}'));
          }
          final envanter = envanterSnap.data ?? const <EnvanterItem>[];

          return StreamBuilder<List<Ihtiyac>>(
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
                    margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'İhtiyaç #${ihtiyac.id} (${ihtiyac.isim} ${ihtiyac.soyisim})',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                SizedBox(height: 6),
                                ...ihtiyac.urunler.entries.map(
                                  (e) => Text('${e.key}: ${e.value} adet'),
                                ),
                                SizedBox(height: 6),
                                Text('Adres: ${ihtiyac.adresTarifi}'),
                                if (ihtiyac.not.isNotEmpty)
                                  Text('Not: ${ihtiyac.not}'),
                                SizedBox(height: 6),
                                Row(
                                  children: [
                                    Text(
                                      'Tarih: ${DateFormat('dd/MM/yyyy').format(ihtiyac.timestamp)}',
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Saat: ${DateFormat('HH:mm').format(ihtiyac.timestamp)}',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: 160),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    minimumSize: Size(0, 32),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity(
                                      horizontal: -4,
                                      vertical: -4,
                                    ),
                                  ),
                                  icon: Icon(
                                    Icons.check,
                                    color: Colors.green,
                                    size: 18,
                                  ),
                                  label: Text(
                                    'Onayla',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onPressed: () => _onayIhtiyac(ihtiyac),
                                ),
                                SizedBox(height: 4),
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    minimumSize: Size(0, 32),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity(
                                      horizontal: -4,
                                      vertical: -4,
                                    ),
                                  ),
                                  icon: Icon(
                                    Icons.close,
                                    color: Colors.red,
                                    size: 18,
                                  ),
                                  label: Text(
                                    'Reddet',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onPressed: () => _reddetIhtiyac(ihtiyac),
                                ),
                                SizedBox(height: 4),
                                if (hasMissing)
                                  TextButton.icon(
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      minimumSize: Size(0, 32),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity(
                                        horizontal: -4,
                                        vertical: -4,
                                      ),
                                    ),
                                    icon: Icon(
                                      Icons.send,
                                      color: Colors.blue,
                                      size: 18,
                                    ),
                                    label: Text(
                                      'Kurumdan iste',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
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
