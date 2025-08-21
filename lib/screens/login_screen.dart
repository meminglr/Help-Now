import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Giriş Yap')),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  decoration: InputDecoration(labelText: 'E-posta'),
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (value) => _email = value,
                  validator: (value) => value!.isEmpty ? 'E-posta girin' : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Şifre'),
                  obscureText: true,
                  onChanged: (value) => _password = value,
                  validator: (value) => value!.isEmpty ? 'Şifre girin' : null,
                ),
                SizedBox(height: 20),
                if (_errorMessage != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() {
                              _isLoading = true;
                              _errorMessage = null;
                            });
                            try {
                              final user = await _authService.signIn(
                                _email,
                                _password,
                              );
                              if (user != null) {
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/main',
                                );
                              } else {
                                setState(() {
                                  _errorMessage = 'Kullanıcı bulunamadı';
                                });
                              }
                            } catch (e) {
                              setState(() {
                                _errorMessage = e.toString().replaceFirst(
                                  'Exception: ',
                                  '',
                                );
                              });
                            } finally {
                              setState(() => _isLoading = false);
                            }
                          }
                        },
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Giriş Yap'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/register');
                  },
                  child: Text('Hesabınız yok mu? Kayıt olun'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
