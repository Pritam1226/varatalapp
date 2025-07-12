import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProfileDetailScreen extends StatelessWidget {
  final String contactId;

  const ProfileDetailScreen({super.key, required this.contactId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Detail')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(contactId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('User not found'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: data['profileImageUrl'] != ''
                      ? NetworkImage(data['profileImageUrl'])
                      : null,
                  child: data['profileImageUrl'] == ''
                      ? const Icon(Icons.person, size: 50)
                      : null,
                ),
                const SizedBox(height: 16),
                Text(data['name'] ?? 'N/A', style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 8),
                Text(data['bio'] ?? 'No bio'),
              ],
            ),
          );
        },
      ),
    );
  }
}
