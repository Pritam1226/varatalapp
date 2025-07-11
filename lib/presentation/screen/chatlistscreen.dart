import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:intl/intl.dart';

import 'addcontact_screen.dart';
import 'chatscreen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart'; // ✅ Import the settings screen

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  String formatTime(Timestamp timestamp) =>
      DateFormat('hh:mm a').format(timestamp.toDate());

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'profile':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                  break;
                case 'new_group':
                  // TODO: implement new group flow
                  break;
                case 'settings':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()), // ✅ Open settings
                  );
                  break;
                case 'logout':
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) Navigator.popUntil(context, (r) => r.isFirst);
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'profile', child: Text('Profile')),
              PopupMenuItem(value: 'new_group', child: Text('New Group')),
              PopupMenuItem(value: 'settings', child: Text('Settings')),
              PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
        ],
      ),
      body: currentUserId == null
          ? const Center(child: Text('User not logged in'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .where('users', arrayContains: currentUserId)
                  .orderBy('lastMessageTime', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }

                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('No chats found'));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, idx) {
                    final doc = docs[idx];
                    final chatId = doc.id;
                    final data = doc.data() as Map<String, dynamic>;
                    final users = List<String>.from(data['users'] ?? []);
                    final otherId = users.firstWhere(
                      (uid) => uid != currentUserId,
                      orElse: () => '',
                    );

                    String contactName = 'Contact';
                    if (data.containsKey('contactNames')) {
                      final names = Map<String, dynamic>.from(data['contactNames']);
                      contactName = names[otherId] ?? contactName;
                    }

                    final lastMsg = data['lastMessage'] ?? '';
                    final time = data['lastMessageTime'] as Timestamp?;
                    final timeStr = time != null ? formatTime(time) : '';

                    return Dismissible(
                      key: Key(chatId),
                      background: _buildSwipeActionLeft(),
                      secondaryBackground: _buildSwipeActionRight(),
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.endToStart) {
                          final confirm = await _showConfirmDialog(context, 'Delete this chat?');
                          if (confirm) {
                            await FirebaseFirestore.instance.collection('chats').doc(chatId).delete();
                          }
                          return confirm;
                        } else if (direction == DismissDirection.startToEnd) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$contactName archived')),
                          );
                          // Optional: set 'archived' flag in the chat document
                          return false;
                        }
                        return false;
                      },
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(contactName),
                        subtitle: Text(
                          lastMsg.isNotEmpty ? lastMsg : 'Start a chat…',
                          style: TextStyle(
                            fontStyle: lastMsg.isEmpty ? FontStyle.italic : null,
                          ),
                        ),
                        trailing: Text(timeStr),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              contactName: contactName,
                              contactId: otherId,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: SpeedDial(
        animatedIcon: AnimatedIcons.menu_close,
        backgroundColor: Theme.of(context).primaryColor,
        tooltip: 'Options',
        children: [
          SpeedDialChild(
            child: const Icon(Icons.person_add),
            label: 'Add Contact',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddContactScreen()),
            ),
          ),
        ],
      ),
    );
  }

  /// Left swipe (Archive)
  Widget _buildSwipeActionLeft() {
    return Container(
      color: Colors.blue,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.centerLeft,
      child: const Row(
        children: [
          Icon(Icons.archive, color: Colors.white),
          SizedBox(width: 8),
          Text('Archive', style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  /// Right swipe (Delete)
  Widget _buildSwipeActionRight() {
    return Container(
      color: Colors.red,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.centerRight,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(Icons.delete, color: Colors.white),
          SizedBox(width: 8),
          Text('Delete', style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  /// Confirm delete dialog
  Future<bool> _showConfirmDialog(BuildContext context, String msg) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Confirm'),
            content: Text(msg),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(ctx, false),
              ),
              ElevatedButton(
                child: const Text('Yes'),
                onPressed: () => Navigator.pop(ctx, true),
              ),
            ],
          ),
        ) ??
        false;
  }
}
