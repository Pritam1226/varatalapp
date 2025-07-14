import 'package:flutter/material.dart';


class ShareInviteScreen extends StatelessWidget {
  const ShareInviteScreen({super.key});

  void _shareAppInvite(BuildContext context) {
    final String message = '''
👋 Hey! Join me on Vartalap Chat App! 🗨️

Download now and start chatting instantly!

📲 https://vartalap.com/download
''';

    
    (message, subject: 'Invite to Vartalap Chat App');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invite a Friend')),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.share),
          label: const Text('Share Vartalap'),
          onPressed: () => _shareAppInvite(context),
        ),
      ),
    );
  }
}
