import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'chatscreen.dart'; // ⬅️ Make sure this is correct

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
        'uid': user['uid'],
        'name': user['name'],
        'email': user['email'],
        'phone': user['phone'],
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
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final users = snapshot.data!.docs.where((doc) => doc.id != currentUserId).toList();

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index].data() as Map<String, dynamic>;

              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(user['name'] ?? 'No name'),
                subtitle: Text(user['email'] ?? ''),
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
                              contactName: user['name'] ?? '',
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
