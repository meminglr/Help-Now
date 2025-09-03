import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user.dart';

class HomeScreen extends StatefulWidget {
  final void Function(int index)? onNavigateToTab;
  final int? gonulluOnayTabIndex;
  final int? envanterTabIndex;
  final int? kurumYonetimTabIndex;
  final int? raporTabIndex;

  HomeScreen({
    this.onNavigateToTab,
    this.gonulluOnayTabIndex,
    this.envanterTabIndex,
    this.kurumYonetimTabIndex,
    this.raporTabIndex,
  });
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder<AppUser?>(
      stream: _authService.user,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData) {
          return Center(child: Text('Kullanıcı bulunamadı'));
        }
        final user = snapshot.data!;
        return Scaffold(
          appBar: AppBar(title: Text('Deprem Yardım Uygulaması')),
          body: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hoş Geldiniz, ${user.isim}!'),
                        Text('Rolünüz: ${user.role}'),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sistem Genel Durum',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        SizedBox(height: 8),
                        StreamBuilder<Map<String, int>>(
                          stream: _firestoreService.getUserRoleCounts(),
                          builder: (context, countsSnap) {
                            if (countsSnap.connectionState ==
                                ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }
                            if (countsSnap.hasError || !countsSnap.hasData) {
                              return Text('Sayım yüklenemedi');
                            }
                            final counts = countsSnap.data!;
                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _StatChip(
                                  label: 'Depremzede',
                                  value: counts['depremzede'] ?? 0,
                                  color: Colors.orange,
                                ),
                                _StatChip(
                                  label: 'Gönüllü',
                                  value: counts['gonullu'] ?? 0,
                                  color: Colors.green,
                                ),
                                _StatChip(
                                  label: 'Kurum',
                                  value: counts['kurum'] ?? 0,
                                  color: Colors.blue,
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                if (user.role == 'gonullu') ...[
                  SizedBox(height: 12),
                  InkWell(
                    onTap: () {
                      if (widget.onNavigateToTab != null &&
                          widget.gonulluOnayTabIndex != null) {
                        widget.onNavigateToTab!(widget.gonulluOnayTabIndex!);
                      }
                    },
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.blue),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Onay Bekleyen İstekler',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  SizedBox(height: 6),
                                  StreamBuilder<int>(
                                    stream: _firestoreService
                                        .getIhtiyaclar()
                                        .map(
                                          (list) => list
                                              .where(
                                                (i) =>
                                                    i.durum == 'beklemede' ||
                                                    i.durum == 'yetersiz',
                                              )
                                              .length,
                                        ),
                                    builder: (context, snap) {
                                      if (!snap.hasData)
                                        return Text('Yükleniyor...');
                                      return Text(
                                        '${snap.data} istek onay bekliyor',
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  InkWell(
                    onTap: () {
                      if (widget.onNavigateToTab != null &&
                          widget.envanterTabIndex != null) {
                        widget.onNavigateToTab!(widget.envanterTabIndex!);
                      }
                    },
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.inventory, color: Colors.green),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Depo Özeti',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  SizedBox(height: 6),
                                  StreamBuilder<Map<String, int>>(
                                    stream: _firestoreService.getEnvanter().map(
                                      (list) {
                                        final urunSayisi = list.length;
                                        final toplamBirim = list.fold<int>(
                                          0,
                                          (sum, e) => sum + e.miktar,
                                        );
                                        return {
                                          'urunSayisi': urunSayisi,
                                          'toplamBirim': toplamBirim,
                                        };
                                      },
                                    ),
                                    builder: (context, snap) {
                                      if (!snap.hasData)
                                        return Text('Yükleniyor...');
                                      final data = snap.data!;
                                      return Text(
                                        'Ürün: ${data['urunSayisi']} • Toplam birim: ${data['toplamBirim']}',
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  InkWell(
                    onTap: () {
                      if (widget.onNavigateToTab != null &&
                          widget.raporTabIndex != null) {
                        widget.onNavigateToTab!(widget.raporTabIndex!);
                      }
                    },
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.assessment, color: Colors.purple),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Depo Raporu',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Giriş-çıkış hareketleri, günlük özet ve detaylı raporlar',
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                if (user.role == 'kurum') ...[
                  SizedBox(height: 12),
                  InkWell(
                    onTap: () {
                      if (widget.onNavigateToTab != null &&
                          widget.kurumYonetimTabIndex != null) {
                        widget.onNavigateToTab!(widget.kurumYonetimTabIndex!);
                      }
                    },
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.report_problem, color: Colors.orange),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Eksik İhtiyaçlar',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  SizedBox(height: 6),
                                  StreamBuilder<int>(
                                    stream: _firestoreService
                                        .getEksikIstekler()
                                        .map((list) => list.length),
                                    builder: (context, snap) {
                                      if (!snap.hasData)
                                        return Text('Yükleniyor...');
                                      return Text(
                                        '${snap.data} eksik ihtiyaç var',
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  InkWell(
                    onTap: () {
                      if (widget.onNavigateToTab != null &&
                          widget.kurumYonetimTabIndex != null) {
                        widget.onNavigateToTab!(widget.kurumYonetimTabIndex!);
                      }
                    },
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.volunteer_activism, color: Colors.pink),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bağış Yap',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Birlikte daha güçlüyüz! Bağışlarınızla ihtiyaçları karşılayalım.',
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: $value'),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.6)),
      avatar: CircleAvatar(backgroundColor: color, radius: 8),
    );
  }
}
