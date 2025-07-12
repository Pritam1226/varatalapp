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

          final String name = data['name'] ?? 'N/A';
          final String bio = data['bio'] ?? 'No bio';
          final String? profileImageUrl = data['profileImageUrl'];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: (profileImageUrl != null && profileImageUrl.isNotEmpty)
                      ? NetworkImage(profileImageUrl)
                      : null,
                  child: (profileImageUrl == null || profileImageUrl.isEmpty)
                      ? const Icon(Icons.person, size: 50)
                      : null,
                ),
                const SizedBox(height: 16),
                Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(bio, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
              ],
            ),
          );
        },
      ),
    );
  }
}
