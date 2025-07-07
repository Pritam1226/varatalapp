import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // ✅ Firebase core import
import 'package:varatalapp/config/theme/app_theme.dart';
import 'package:varatalapp/presentation/screen/loginscreen.dart';
import 'package:varatalapp/presentation/screen/chatlistscreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // ✅ Required before Firebase init
  await Firebase.initializeApp(); // ✅ Initialize Firebase
  runApp(const MyApp()); // ✅ Run the app
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vartalap Chat App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
      routes: {
        '/chatList': (context) => const ChatListScreen(),
      },
    );
  }
}
