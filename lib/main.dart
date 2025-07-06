import 'package:flutter/material.dart';
import 'package:varatalapp/config/theme/app_theme.dart';
import 'package:varatalapp/presentation/screen/loginscreen.dart';
import 'package:varatalapp/presentation/screen/chatlistscreen.dart';

void main() {
  runApp(const MyApp());
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
