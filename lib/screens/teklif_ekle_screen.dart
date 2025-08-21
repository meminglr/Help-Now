import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/teklif.dart';
import '../services/firestore_service.dart';

class TeklifEkleScreen extends StatefulWidget {
  final String ihtiyacId;

  const TeklifEkleScreen({required this.ihtiyacId});

  @override
  _TeklifEkleScreenState createState() => _TeklifEkleScreenState();
}

class _TeklifEkleScreenState extends State<TeklifEkleScreen> {
  final _formKey = GlobalKey<FormState>();
  String _aciklama = '';
  bool _isLoading = false;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Yardım Teklifi Yap')),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  decoration: InputDecoration(labelText: 'Teklif Açıklaması'),
                  maxLines: 3,
                  onChanged: (value) {
                    _aciklama = value;
                  },
                  validator: (value) =>
                      value!.isEmpty ? 'Açıklama girin' : null,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() => _isLoading = true);
                            try {
                              Teklif teklif = Teklif(
                                id: DateTime.now().millisecondsSinceEpoch
                                    .toString(),
                                ihtiyacId: widget.ihtiyacId,
                                gonulluId:
                                    FirebaseAuth.instance.currentUser!.uid,
                                aciklama: _aciklama,
                                timestamp: DateTime.now(),
                              );
                              await _firestoreService.addTeklif(teklif);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Teklif gönderildi!')),
                              );
                              Navigator.pop(context);
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Hata: $e')),
                              );
                            } finally {
                              setState(() => _isLoading = false);
                            }
                          }
                        },
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Teklifi Gönder'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
