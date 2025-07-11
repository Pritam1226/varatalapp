import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:varatalapp/controller/theme_controller.dart';
import 'package:varatalapp/config/theme/app_theme.dart';
import 'package:varatalapp/presentation/screen/loginscreen.dart';
import 'package:varatalapp/presentation/screen/chatlistscreen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();           // ✅ Firebase init
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeController(),     // ✅ Provide theme controller
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeController>(
      builder: (context, themeController, _) {
        return MaterialApp(
          title: 'Vartalap Chat App',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,        // 🌞 Light theme
          darkTheme: AppTheme.darkTheme,     // 🌚 Dark theme (add it in app_theme.dart)
          themeMode: themeController.currentTheme,
          home: const LoginScreen(),
          routes: {
            '/chatList': (_) => const ChatListScreen(),
          },
        );
      },
    );
  }
}
