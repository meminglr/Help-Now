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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Kurum Yönetimi'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 32.0,
            ),
            child: Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _bagisFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Bağış Yap',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      StreamBuilder<List<String>>(
                        stream: _firestoreService.getEnvanterAdlari(),
                        builder: (context, snapshot) {
                          final suggestions = snapshot.data ?? const <String>[];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Ürün adı'),
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
                                        decoration: const InputDecoration(
                                          hintText: 'Ürün adı yazın veya seçin',
                                          prefixIcon: Icon(
                                            Icons.inventory_2_outlined,
                                          ),
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
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _miktarController,
                        decoration: const InputDecoration(
                          labelText: 'Miktar',
                          prefixIcon: Icon(Icons.numbers),
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
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 48,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.volunteer_activism),
                          label: const Text(
                            'Bağışla',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
                                const SnackBar(
                                  content: Text('Bağış envantere eklendi'),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Hata: $e')),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _firestoreService.getEksikIstekler(),
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
                      'Eksik istek bulunamadı',
                      style: TextStyle(color: Colors.black54),
                    ),
                  );
                }

                final istekler = snapshot.data!;
                return ListView.builder(
                  itemCount: istekler.length,
                  itemBuilder: (context, index) {
                    final istek = istekler[index];
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'İstek #${istek['ihtiyacId']}',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            ...istek['eksikUrunler'].entries
                                .map<Widget>(
                                  (e) => Text(
                                    '${e.key}: ${e.value} adet',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                )
                                .toList(),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (istek['durum'] == 'beklemede') ...[
                                  FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    icon: const Icon(Icons.check, size: 18),
                                    label: const Text('Onayla'),
                                    onPressed: () async {
                                      try {
                                        await _firestoreService
                                            .updateEksikIstekDurum(
                                              istek['id'],
                                              'onaylandı',
                                              eksikUrunler:
                                                  istek['eksikUrunler'],
                                            );
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
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
                                  const SizedBox(width: 8),
                                  FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    icon: const Icon(Icons.close, size: 18),
                                    label: const Text('Reddet'),
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
                                          const SnackBar(
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
                                ] else ...[
                                  Text(
                                    istek['durum'],
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
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
