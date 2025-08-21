import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ihtiyac.dart';
import '../services/firestore_service.dart';

class IhtiyacBildirimScreen extends StatefulWidget {
  @override
  _IhtiyacBildirimScreenState createState() => _IhtiyacBildirimScreenState();
}

class _IhtiyacBildirimScreenState extends State<IhtiyacBildirimScreen>
    with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  String _kategori = 'Gıda';
  String _aciklama = '';
  bool _isLoading = false;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  bool get wantKeepAlive => true;

  Future<void> _submitIhtiyac() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
        );
        Ihtiyac ihtiyac = Ihtiyac(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: FirebaseAuth.instance.currentUser!.uid,
          kategori: _kategori,
          aciklama: _aciklama,
          latitude: position.latitude,
          longitude: position.longitude,
          timestamp: DateTime.now(),
        );
        await _firestoreService.addIhtiyac(ihtiyac);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('İhtiyaç bildirildi')));
        _formKey.currentState!.reset();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(title: Text('İhtiyaç Bildir')),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _kategori,
                  items: ['Gıda', 'Su', 'Barınma', 'Sağlık']
                      .map(
                        (kategori) => DropdownMenuItem(
                          value: kategori,
                          child: Text(kategori),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _kategori = value!;
                    });
                  },
                  decoration: InputDecoration(labelText: 'Kategori'),
                ),
                SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Açıklama'),
                  maxLines: 3,
                  onChanged: (value) => _aciklama = value,
                  validator: (value) =>
                      value!.isEmpty ? 'Açıklama girin' : null,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitIhtiyac,
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('İhtiyacı Bildir'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
