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

  Future<void> _ekleUrun() async {
    if (_urunAdiController.text.isEmpty || _urunMiktarController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ürün adı ve miktar girin')));
      return;
    }
    try {
      final miktar = int.parse(_urunMiktarController.text);
      await _firestoreService.donateEnvanter(_urunAdiController.text, miktar);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ürün miktarı artırıldı')));
      _calculateTotalStok();
      _urunAdiController.clear();
      _urunMiktarController.clear();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }

  Future<void> _guncelleUrun() async {
    if (_urunAdiController.text.isEmpty || _urunMiktarController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ürün adı ve miktar girin')));
      return;
    }
    try {
      final urunId = _normalizeProductId(_urunAdiController.text);
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

  String _normalizeProductId(String name) {
    String s = name.trim().toLowerCase();
    const Map<String, String> trMap = {
      'ç': 'c',
      'ğ': 'g',
      'ı': 'i',
      'ö': 'o',
      'ş': 's',
      'ü': 'u',
      'â': 'a',
      'î': 'i',
      'û': 'u',
    };
    trMap.forEach((k, v) => s = s.replaceAll(k, v));
    s = s
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return s;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Depo Yönetimi'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Depo Doluluk Durumu',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Toplam Stok: $_totalStok birim',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      StreamBuilder<List<EnvanterItem>>(
                        stream: _firestoreService.getEnvanter(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
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
                                'Depoda ürün bulunamadı',
                                style: TextStyle(color: Colors.black54),
                              ),
                            );
                          }

                          final envanter = snapshot.data!;
                          return Column(
                            children: envanter.map((item) {
                              return Card(
                                elevation: 0,
                                color: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                child: ListTile(
                                  title: Text(
                                    '${item.ad} (Stok: ${item.miktar})',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge,
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () async {
                                      try {
                                        await _firestoreService
                                            .updateEnvanterMiktar(item.id, 0);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              '${item.ad} kaldırıldı',
                                            ),
                                          ),
                                        );
                                        _calculateTotalStok();
                                      } catch (e) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(content: Text('Hata: $e')),
                                        );
                                      }
                                    },
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 0.0,
              ),
              child: Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Yeni Ürün Ekle / Güncelle',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      StreamBuilder<List<String>>(
                        stream: _firestoreService.getEnvanterAdlari(),
                        builder: (context, snapshot) {
                          final suggestions = snapshot.data ?? const <String>[];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Ürün Adı'),
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
                                      return TextField(
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
                                          _urunAdiController.text = v;
                                        },
                                      );
                                    },
                                onSelected: (String selection) {
                                  _urunAdiController.text = selection;
                                },
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _urunMiktarController,
                        decoration: const InputDecoration(
                          labelText: 'Miktar',
                          prefixIcon: Icon(Icons.numbers),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _ekleUrun,
                              child: const Text(
                                'Ekle (Arttır)',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _guncelleUrun,
                              child: const Text(
                                'Güncelle (Set Et)',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
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
