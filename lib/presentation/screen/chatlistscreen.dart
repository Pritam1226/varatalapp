import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:intl/intl.dart';
import 'addcontact_screen.dart';
import 'chatscreen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  String formatTime(Timestamp timestamp) {
    final date = timestamp.toDate();
    return DateFormat('hh:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chats"),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              // Add logic here
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'new_group', child: Text('New Group')),
              PopupMenuItem(value: 'settings', child: Text('Settings')),
              PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .collection('contacts')
            .snapshots(),
        builder: (context, contactSnapshot) {
          if (contactSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final contacts = contactSnapshot.data?.docs ?? [];
          print("📥 Loaded ${contacts.length} contacts");

          if (contacts.isEmpty) {
            return const Center(child: Text('No chats found.'));
          }

          return ListView.builder(
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final contact = contacts[index].data() as Map<String, dynamic>;
              final contactId = contact['contactId'] ?? contact['uid'];
              final contactName = contact['contactName'] ?? contact['name'] ?? 'Unknown';

              if (contactId == null) return const SizedBox.shrink();

              final currentUser = FirebaseAuth.instance.currentUser!;
              final chatId = getChatId(currentUser.uid, contactId);

              return FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('Chats')
                    .doc(chatId)
                    .collection('messages')
                    .orderBy('timestamp', descending: true)
                    .limit(1)
                    .get(),
                builder: (context, messageSnapshot) {
                  if (messageSnapshot.connectionState == ConnectionState.waiting) {
                    return const ListTile(
                      title: Text("Loading..."),
                      subtitle: Text("Fetching message"),
                    );
                  }

                  String lastMessage = '';
                  Timestamp? time;

                  if (messageSnapshot.hasData &&
                      messageSnapshot.data!.docs.isNotEmpty) {
                    final message = messageSnapshot.data!.docs.first;
                    lastMessage = message['text'] ?? '';
                    time = message['timestamp'];
                  }

                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(contactName),
                    subtitle: Text(lastMessage.isNotEmpty ? lastMessage : "Say hi! 👋"),
                    trailing: time != null
                        ? Text(formatTime(time))
                        : const SizedBox.shrink(),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            contactName: contactName,
                            contactId: contactId,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: SpeedDial(
        animatedIcon: AnimatedIcons.menu_close,
        backgroundColor: Theme.of(context).primaryColor,
        tooltip: "Options",
        children: [
          SpeedDialChild(
            child: const Icon(Icons.person_add),
            label: 'Add Contact',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddContactScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  String getChatId(String userId, String contactId) {
    return (userId.compareTo(contactId) < 0)
        ? '${userId}_$contactId'
        : '${contactId}_$userId';
  }
}
