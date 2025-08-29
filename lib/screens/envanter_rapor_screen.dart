import 'package:flutter/material.dart';
import '../models/envanter.dart';
import '../services/firestore_service.dart';

class EnvanterRaporScreen extends StatefulWidget {
  @override
  _EnvanterRaporScreenState createState() => _EnvanterRaporScreenState();
}

class _EnvanterRaporScreenState extends State<EnvanterRaporScreen>
    with AutomaticKeepAliveClientMixin {
  final FirestoreService _firestoreService = FirestoreService();
  int _totalStok = 0;
  int _totalUrunCesidi = 0;
  List<EnvanterItem> _envanter = [];
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadEnvanterData();
  }

  Future<void> _loadEnvanterData() async {
    try {
      final envanter = await _firestoreService.getEnvanter().first;
      setState(() {
        _envanter = envanter;
        _totalStok = envanter.fold<int>(0, (sum, item) => sum + item.miktar);
        _totalUrunCesidi = envanter.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Envanter verisi yüklenemedi: $e')),
      );
    }
  }

  // Grafikler kaldırıldı: stok dağılımı ve en yüksek stok grafikleri

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Depo Raporu'),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _loadEnvanterData),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadEnvanterData,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Özet Kartları
                    _buildSummaryCards(),
                    SizedBox(height: 24),

                    // Günlük/Aylık Hareket Özetleri
                    _buildMovementSummaries(),
                    SizedBox(height: 24),

                    // Grafikler kaldırıldı

                    // Son Hareketler
                    _buildRecentMovements(),
                    SizedBox(height: 24),

                    // Detaylı Liste
                    _buildDetailedList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double spacing = 16;
        final bool isNarrow = constraints.maxWidth < 360;
        final int columns = isNarrow ? 1 : 2;
        final double itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        final List<Widget> cards = [
          _buildSummaryCard(
            'Toplam Stok',
            '$_totalStok',
            Icons.inventory,
            Colors.blue,
          ),
          _buildSummaryCard(
            'Ürün Çeşidi',
            '$_totalUrunCesidi',
            Icons.category,
            Colors.green,
          ),
        ];

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards
              .map((c) => SizedBox(width: itemWidth, child: c))
              .toList(),
        );
      },
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovementSummaries() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Günlük ve Aylık Hareketler',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final bool isNarrow = constraints.maxWidth < 420;
                // responsive yerleşim: dar ekranda Column, genişte Row

                final gunluk = StreamBuilder<Map<String, int>>(
                  stream: _firestoreService.getGunlukGirisCikis(),
                  builder: (context, snapshot) {
                    final giris = snapshot.data?['giris'] ?? 0;
                    final cikis = snapshot.data?['cikis'] ?? 0;
                    return _buildMovementTile(
                      'Bugün',
                      giris,
                      cikis,
                      Icons.today,
                      Colors.indigo,
                    );
                  },
                );

                final aylik = StreamBuilder<Map<String, int>>(
                  stream: _firestoreService.getAylikGirisCikis(),
                  builder: (context, snapshot) {
                    final giris = snapshot.data?['giris'] ?? 0;
                    final cikis = snapshot.data?['cikis'] ?? 0;
                    return _buildMovementTile(
                      'Bu Ay',
                      giris,
                      cikis,
                      Icons.calendar_month,
                      Colors.teal,
                    );
                  },
                );

                if (isNarrow) {
                  return Column(
                    children: [gunluk, SizedBox(height: 12), aylik],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: gunluk),
                    SizedBox(width: 12),
                    Expanded(child: aylik),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovementTile(
    String title,
    int giris,
    int cikis,
    IconData icon,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              SizedBox(width: 8),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChip('Giriş', giris.toString(), Colors.green),
              _buildChip('Çıkış', cikis.toString(), Colors.red),
              _buildChip('Net', (giris - cikis).toString(), Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, String value, Color color) {
    return Chip(
      label: Text('$label: $value'),
      backgroundColor: color.withValues(alpha: 0.15),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
    );
  }

  // _buildPieChart kaldırıldı

  // Legend kaldırıldı
  // _buildBarChart kaldırıldı

  Widget _buildRecentMovements() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Son Hareketler',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 12),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _firestoreService.getSonHareketler(limit: 20),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Hata: ${snapshot.error}'));
                }
                final hareketler = snapshot.data ?? [];
                if (hareketler.isEmpty) {
                  return Text('Kayıtlı hareket bulunamadı');
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: hareketler.length,
                  separatorBuilder: (_, __) => Divider(height: 1),
                  itemBuilder: (context, index) {
                    final h = hareketler[index];
                    final bool giris = (h['degisim'] as int) > 0;
                    final DateTime ts = (h['timestamp'] as DateTime);
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: giris ? Colors.green : Colors.red,
                        child: Icon(
                          giris ? Icons.arrow_downward : Icons.arrow_upward,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      title: Text(h['ad'] ?? h['itemId']),
                      subtitle: Text('${ts.toLocal()}'),
                      trailing: Text(
                        (giris ? '+' : '-') + (h['degisim'].abs()).toString(),
                        style: TextStyle(
                          color: giris ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedList() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detaylı Depo Listesi',
              style: Theme.of(context).textTheme.titleMedium,
            ),
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
                  return Center(child: Text('Depoda ürün bulunamadı'));
                }

                final envanter = snapshot.data!;
                final sortedEnvanter = List<EnvanterItem>.from(envanter)
                  ..sort((a, b) => b.miktar.compareTo(a.miktar));

                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: sortedEnvanter.length,
                  itemBuilder: (context, index) {
                    final item = sortedEnvanter[index];
                    final percentage = (item.miktar / _totalStok) * 100;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getColorByPercentage(percentage),
                        child: Text(
                          '${percentage.toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(item.ad),
                      subtitle: Text('Stok: ${item.miktar} birim'),
                      trailing: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getColorByPercentage(
                            percentage,
                          ).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${item.miktar}',
                          style: TextStyle(
                            color: _getColorByPercentage(percentage),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorByPercentage(double percentage) {
    if (percentage >= 20) return Colors.green;
    if (percentage >= 10) return Colors.orange;
    return Colors.red;
  }
}
