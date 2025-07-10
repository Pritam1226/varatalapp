
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:intl/intl.dart';
import 'addcontact_screen.dart';
import 'chatscreen.dart';

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
            onSelected: (value) {},
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
            .collection('chats')
            .snapshots(),
        builder: (context, chatSnapshot) {
          if (!chatSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final chatDocs = chatSnapshot.data!.docs;

          if (chatDocs.isEmpty) {
            return const Center(child: Text('No chats found.'));
          }

          return ListView.builder(
            itemCount: chatDocs.length,
            itemBuilder: (context, index) {
              final chatDoc = chatDocs[index];
              final chatId = chatDoc.id;
              final participantId = chatDoc['participantId'];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(participantId)
                    .get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const ListTile(title: Text('Loading...'));
                  }

                  final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                  final contactName = userData['name'] ?? 'Unknown';

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(currentUserId)
                        .collection('chats')
                        .doc(chatId)
                        .collection('messages')
                        .orderBy('timestamp', descending: true)
                        .limit(1)
                        .snapshots(),
                    builder: (context, msgSnapshot) {
                      String lastMessage = '';
                      Timestamp? time;

                      if (msgSnapshot.hasData &&
                          msgSnapshot.data!.docs.isNotEmpty) {
                        final msg = msgSnapshot.data!.docs.first;
                        lastMessage = msg['text'];
                        time = msg['timestamp'];
                      }

                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(contactName),
                        subtitle: Text(
                          lastMessage.isNotEmpty ? lastMessage : 'Start a chat...',
                          style: TextStyle(
                            fontStyle:
                                lastMessage.isEmpty ? FontStyle.italic : null,
                          ),
                        ),
                        trailing: time != null
                            ? Text(formatTime(time))
                            : const SizedBox.shrink(),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                contactName: contactName,
                                contactId: participantId,
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
}
