import 'package:flutter/material.dart';

class ChatWallpaperScreen extends StatelessWidget {
  const ChatWallpaperScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat Wallpaper')),
      body: const Center(
        child: Text('Choose or upload wallpaper.'),
      ),
    );
  }
}
