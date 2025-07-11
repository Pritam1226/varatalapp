import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:varatalapp/controller/theme_controller.dart'; // ✅ Your theme controller

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: themeController.isDarkMode,
            onChanged: (value) => themeController.toggleTheme(value),
            secondary: const Icon(Icons.dark_mode),
          ),
          // You can add more settings options here
        ],
      ),
    );
  }
}
