import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'chatscreen.dart';

class AddContactScreen extends StatelessWidget {
  const AddContactScreen({super.key});

  Future<void> addToContacts(BuildContext context, Map<String, dynamic> user) async {
    final currentUserUid = FirebaseAuth.instance.currentUser!.uid;
    final contactDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserUid)
        .collection('contacts')
        .doc(user['uid']);

    final docSnapshot = await contactDocRef.get();

    if (!docSnapshot.exists) {
      await contactDocRef.set({
        'contactId': user['uid'], // 🔄 consistent naming
        'contactName': user['name'] ?? '',
        'email': user['email'] ?? '',
        'phone': user['phone'] ?? '',
        'addedAt': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Contact added")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Already in contacts")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("Add Contacts")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data?.docs
                  .where((doc) => doc.id != currentUserId)
                  .toList() ??
              [];

          if (users.isEmpty) {
            return const Center(child: Text("No users found."));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index].data() as Map<String, dynamic>;
              final userName = user['name'] ?? 'No name';
              final userEmail = user['email'] ?? '';

              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(userName),
                subtitle: Text(userEmail),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chat, color: Colors.green),
                      tooltip: "Start Chat",
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              contactName: userName,
                              contactId: user['uid'],
                            ),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.person_add_alt_1),
                      tooltip: "Add to Contacts",
                      onPressed: () => addToContacts(context, user),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
