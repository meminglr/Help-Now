import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:help_now/features/auth/view/register_screen.dart';
import 'package:help_now/features/auth/view/sign_in.dart';
import 'package:help_now/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        
        useMaterial3: true,
      ),
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
      },
      home: LoginScreen(),
    );
    
  }
}
