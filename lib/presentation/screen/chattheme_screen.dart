import 'package:flutter/material.dart';

class ChatThemeScreen extends StatelessWidget {
  const ChatThemeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat Theme')),
      body: const Center(
        child: Text('Choose your chat theme here.'),
      ),
    );
  }
}
