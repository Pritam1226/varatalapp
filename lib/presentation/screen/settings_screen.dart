import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:varatalapp/controller/theme_controller.dart';
import 'package:varatalapp/presentation/screen/blockedchats_screen.dart';
import 'package:varatalapp/presentation/screen/chattheme_screen.dart';
import 'package:varatalapp/presentation/screen/chatwallpaper_screen.dart';
import 'package:varatalapp/presentation/screen/chathistory_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Text(
              'Appearance',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: themeController.isDarkMode,
            onChanged: (value) => themeController.toggleTheme(value),
            secondary: const Icon(Icons.dark_mode),
          ),

          ListTile(
            leading: const Icon(Icons.format_paint),
            title: const Text('Chat Theme'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatThemeScreen()),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.wallpaper),
            title: const Text('Chat Wallpaper'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatWallpaperScreen()),
              );
            },
          ),

          const Divider(),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Text(
              'Chats & Privacy',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Chat History'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatHistoryScreen()),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.block),
            title: const Text('Blocked Chats'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BlockedChatsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
