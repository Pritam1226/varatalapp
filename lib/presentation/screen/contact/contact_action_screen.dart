import 'package:flutter/material.dart';
import 'package:varatalapp/presentation/screen/chatscreen.dart';
import 'profile_detail_screen.dart'; // You will create this too

class ContactActionScreen extends StatelessWidget {
  final String contactName;
  final String contactId;

  const ContactActionScreen({
    Key? key,
    required this.contactName,
    required this.contactId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(contactName)),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.chat),
            label: const Text('CHAT'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  contactName: contactName,
                  contactId: contactId,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            icon: const Icon(Icons.info),
            label: const Text('DETAIL'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfileDetailScreen(contactId: contactId),
              ),
            ),
          ),
        ],
      ),
    );
  }
}