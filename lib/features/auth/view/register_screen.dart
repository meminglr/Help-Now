import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  String? _selectedRole;
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Kayıt Ol')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'E-posta'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'E-posta girin';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Geçerli bir e-posta girin';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Şifre'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Şifre girin';
                  }
                  if (value.length < 6) {
                    return 'Şifre en az 6 karakter olmalı';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(labelText: 'Şifreyi Onayla'),
                obscureText: true,
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'Şifreler eşleşmiyor';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Rol'),
                items: ['depremzede', 'gonullu', 'kurum']
                    .map((role) => DropdownMenuItem(
                          value: role,
                          child: Text(role),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value;
                  });
                },
                validator: (value) => value == null ? 'Rol seçin' : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                },
                child: Text('Kayıt Ol'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
                child: Text('Zaten hesabın var mı? Giriş yap'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}