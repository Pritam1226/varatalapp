import 'package:flutter/material.dart';

class BlockedChatsScreen extends StatelessWidget {
  const BlockedChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Blocked Chats')),
      body: const Center(
        child: Text('No blocked chats yet.'),
      ),
    );
  }
}
