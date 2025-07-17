import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:varatalapp/controller/theme_controller.dart';
import 'package:varatalapp/config/theme/app_theme.dart';

import 'package:varatalapp/presentation/screen/loginscreen.dart';
import 'package:varatalapp/presentation/screen/home_screen.dart';
import 'package:varatalapp/presentation/screen/group/create_group_screen.dart';
import 'package:varatalapp/presentation/screen/group/group_chat_screen.dart';

import 'package:animated_text_kit/animated_text_kit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeController(),
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
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeController.currentTheme,
          title: 'Vartalap Chat App',
          home: const SplashScreen(),
          routes: {
            '/home': (_) => const HomeScreen(),
            '/login': (_) => const LoginScreen(),
            '/create-group': (_) => const CreateGroupScreen(),
          },
          onGenerateRoute: (settings) {
            if (settings.name == '/group-chat') {
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder: (context) =>
                    GroupChatScreen(groupId: args['groupId']),
              );
            }
            return null;
          },
        );
      },
    );
  }
}

/// Splash Screen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      final user = FirebaseAuth.instance.currentUser;
      Navigator.pushReplacementNamed(
        context,
        user == null ? '/login' : '/home',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo.png', width: 120, height: 120),
            const SizedBox(height: 20),
            AnimatedTextKit(
              totalRepeatCount: 1,
              animatedTexts: [
                TypewriterAnimatedText(
                  " Let's Start Vartalap ",
                  textStyle: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  speed: const Duration(milliseconds: 80),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
