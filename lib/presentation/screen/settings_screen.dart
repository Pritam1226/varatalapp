import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:varatalapp/controller/theme_controller.dart';
import 'package:varatalapp/presentation/screen/blockedchats_screen.dart';
import 'package:varatalapp/presentation/screen/chattheme_screen.dart';
import 'package:varatalapp/presentation/screen/chatwallpaper_screen.dart';
import 'package:varatalapp/presentation/screen/chathistory_screen.dart';
import 'package:varatalapp/presentation/screen/privacy_settings_screen.dart'; // ✅ Import privacy screen

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Section: Appearance
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Text(
              'Appearance',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
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
                MaterialPageRoute(
                  builder: (context) => const ChatThemeScreen(),
                ),
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
                MaterialPageRoute(
                  builder: (context) => const ChatWallpaperScreen(),
                ),
              );
            },
          ),

          const Divider(),

          // Section: Chats & Privacy
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Text(
              'Chats & Privacy',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Settings'), // ✅ New Option
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrivacySettingsScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Chat History'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChatHistoryScreen(),
                ),
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
                MaterialPageRoute(
                  builder: (context) => const BlockedChatsScreen(),
                ),
              );
            },
          ),

          const Divider(),

          // Section: Others
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Text(
              'Others',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_add_alt_1),
            title: const Text('Invite a Friend'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              const String inviteMessage = '''
👋 Hey! Join me on Vartalap Chat App! 🗨

Experience secure and smooth chatting with friends and family!

📲 Download now:
https://vartalap.com/download
''';
              Share.share(inviteMessage);
            },
          ),
        ],
      ),
    );
  }
}
