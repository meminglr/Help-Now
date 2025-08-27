import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class KurumYonetimScreen extends StatefulWidget {
  @override
  _KurumYonetimScreenState createState() => _KurumYonetimScreenState();
}

class _KurumYonetimScreenState extends State<KurumYonetimScreen>
    with AutomaticKeepAliveClientMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final GlobalKey<FormState> _bagisFormKey = GlobalKey<FormState>();
  final TextEditingController _urunAdController = TextEditingController();
  final TextEditingController _miktarController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(title: Text('Kurum Yönetimi')),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Form(
              key: _bagisFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bağış Yap',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: 12),
                  StreamBuilder<List<String>>(
                    stream: _firestoreService.getEnvanterAdlari(),
                    builder: (context, snapshot) {
                      final suggestions = snapshot.data ?? const <String>[];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ürün adı'),
                          const SizedBox(height: 8),
                          Autocomplete<String>(
                            optionsBuilder: (TextEditingValue value) {
                              if (value.text.trim().isEmpty) {
                                return const Iterable<String>.empty();
                              }
                              final lower = value.text.toLowerCase();
                              return suggestions.where(
                                (s) => s.toLowerCase().contains(lower),
                              );
                            },
                            fieldViewBuilder:
                                (
                                  context,
                                  textController,
                                  focusNode,
                                  onFieldSubmitted,
                                ) {
                                  return TextFormField(
                                    controller: textController,
                                    focusNode: focusNode,
                                    decoration: InputDecoration(
                                      hintText: 'Ürün adı yazın veya seçin',
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (v) {
                                      _urunAdController.text = v;
                                    },
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Ürün adı zorunludur';
                                      }
                                      return null;
                                    },
                                  );
                                },
                            onSelected: (String selection) {
                              _urunAdController.text = selection;
                            },
                          ),
                        ],
                      );
                    },
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _miktarController,
                    decoration: InputDecoration(
                      labelText: 'Miktar',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final value = int.tryParse(v ?? '');
                      if (value == null || value <= 0) {
                        return 'Pozitif bir sayı giriniz';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.volunteer_activism),
                      label: Text('Bağışla'),
                      onPressed: () async {
                        if (!_bagisFormKey.currentState!.validate()) return;
                        try {
                          await _firestoreService.donateEnvanter(
                            _urunAdController.text,
                            int.parse(_miktarController.text),
                          );
                          _urunAdController.clear();
                          _miktarController.clear();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Bağış envantere eklendi')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Hata: $e')));
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
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
                            .map<Widget>(
                              (e) => Text('${e.key}: ${e.value} adet'),
                            )
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
                                      await _firestoreService
                                          .updateEksikIstekDurum(
                                            istek['id'],
                                            'onaylandı',
                                            eksikUrunler: istek['eksikUrunler'],
                                          );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'İstek onaylandı ve envanter güncellendi',
                                          ),
                                        ),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text('Hata: $e')),
                                      );
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.close),
                                  onPressed: () async {
                                    try {
                                      await _firestoreService
                                          .updateEksikIstekDurum(
                                            istek['id'],
                                            'reddedildi',
                                          );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('İstek reddedildi'),
                                        ),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
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
          ),
        ],
      ),
    );
  }
}
