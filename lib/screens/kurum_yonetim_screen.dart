import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class KurumYonetimScreen extends StatefulWidget {
  @override
  _KurumYonetimScreenState createState() => _KurumYonetimScreenState();
}

class _KurumYonetimScreenState extends State<KurumYonetimScreen>
    with AutomaticKeepAliveClientMixin {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(title: Text('Eksik Envanter İstekleri')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firestoreService.getEksikIstekler(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Eksik istek bulunamadı'));
          }

          final istekler = snapshot.data!;
          return ListView.builder(
            itemCount: istekler.length,
            itemBuilder: (context, index) {
              final istek = istekler[index];
              return ListTile(
                title: Text('İstek #${istek['ihtiyacId']}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: istek['eksikUrunler'].entries
                      .map<Widget>((e) => Text('${e.key}: ${e.value} adet'))
                      .toList(),
                ),
                trailing: istek['durum'] == 'beklemede'
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.check),
                            onPressed: () async {
                              try {
                                await _firestoreService.updateEksikIstekDurum(
                                  istek['id'],
                                  'onaylandı',
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('İstek onaylandı')),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Hata: $e')),
                                );
                              }
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.close),
                            onPressed: () async {
                              try {
                                await _firestoreService.updateEksikIstekDurum(
                                  istek['id'],
                                  'reddedildi',
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('İstek reddedildi')),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Hata: $e')),
                                );
                              }
                            },
                          ),
                        ],
                      )
                    : Text(istek['durum']),
              );
            },
          );
        },
      ),
    );
  }
}
