import 'package:flutter/material.dart';
import '../models/ihtiyac.dart';
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
      appBar: AppBar(title: Text('İhtiyaç Yönetimi')),
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

          final ihtiyaclar = snapshot.data!;
          return ListView.builder(
            itemCount: ihtiyaclar.length,
            itemBuilder: (context, index) {
              final ihtiyac = ihtiyaclar[index];
              return ListTile(
                title: Text(ihtiyac.kategori),
                subtitle: Text('${ihtiyac.aciklama}\nDurum: ${ihtiyac.durum}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (ihtiyac.durum != 'onaylandı')
                      IconButton(
                        icon: Icon(Icons.check),
                        onPressed: () async {
                          try {
                            await _firestoreService.updateIhtiyacDurum(
                              ihtiyac.id,
                              'onaylandı',
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('İhtiyaç onaylandı')),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text('Hata: $e')));
                          }
                        },
                      ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () async {
                        try {
                          await _firestoreService.deleteIhtiyac(ihtiyac.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('İhtiyaç silindi')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Hata: $e')));
                        }
                      },
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
