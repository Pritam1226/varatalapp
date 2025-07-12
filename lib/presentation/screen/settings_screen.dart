import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:varatalapp/controller/theme_controller.dart';
import 'blockedchats_screen.dart'; // 👈 Add this import

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
          const Divider(),
          ListTile(
            leading: const Icon(Icons.block),
            title: const Text('Blocked Chats'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BlockedChatsScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
