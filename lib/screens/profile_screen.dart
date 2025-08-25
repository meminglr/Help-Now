import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import '../services/firestore_service.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with AutomaticKeepAliveClientMixin {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _phone = '';
  bool _isLoading = false;

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
        _name = user.name ?? '';
        _phone = user.phone ?? '';

        return Scaffold(
          appBar: AppBar(title: Text('Profil')),
          body: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      initialValue: user.email,
                      decoration: InputDecoration(
                        labelText: 'E-posta (Değiştirilemez)',
                      ),
                      enabled: false,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      initialValue: _name,
                      decoration: InputDecoration(labelText: 'İsim'),
                      onChanged: (value) => _name = value,
                      validator: (value) =>
                          value!.isEmpty ? 'İsim girin' : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      initialValue: _phone,
                      decoration: InputDecoration(labelText: 'Telefon'),
                      keyboardType: TextInputType.phone,
                      onChanged: (value) => _phone = value,
                      validator: (value) =>
                          value!.isEmpty ? 'Telefon girin' : null,
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () async {
                              if (_formKey.currentState!.validate()) {
                                setState(() => _isLoading = true);
                                try {
                                  await _firestoreService.updateUserProfile(
                                    FirebaseAuth.instance.currentUser!.uid,
                                    {'name': _name, 'phone': _phone},
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Profil güncellendi'),
                                    ),
                                  );
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
                          : Text('Profili Güncelle'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
