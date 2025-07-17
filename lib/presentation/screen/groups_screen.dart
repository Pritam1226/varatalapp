import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:varatalapp/presentation/screen/group/create_group_screen.dart';
import 'package:varatalapp/presentation/screen/group/group_chat_screen.dart';

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  String formatTime(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    if (now.difference(date).inDays == 0) {
      return DateFormat('hh:mm a').format(date);
    } else {
      return DateFormat('dd MMM').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      return const Center(child: Text('User not logged in'));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Groups')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('groups')
            .where('members', arrayContains: currentUserId)
            .orderBy('lastMessageTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No groups yet',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final groupId = docs[index].id;
              final name = data['groupName'] ?? 'Unnamed Group';
              final lastMsg = data['lastMessage'] ?? '';
              final profileUrl = data['groupImageUrl'];
              final time = data['lastMessageTime'] as Timestamp?;
              final timeStr = time != null ? formatTime(time) : '';

              return ListTile(
                leading: CircleAvatar(
                  radius: 25,
                  backgroundImage: profileUrl != null
                      ? NetworkImage(profileUrl)
                      : null,
                  child: profileUrl == null ? const Icon(Icons.group) : null,
                ),
                title: Text(name),
                subtitle: Text(
                  lastMsg.isNotEmpty ? lastMsg : 'Start group chat…',
                  style: TextStyle(
                    fontStyle: lastMsg.isEmpty ? FontStyle.italic : null,
                  ),
                ),
                trailing: Text(timeStr, style: const TextStyle(fontSize: 12)),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GroupChatScreen(groupId: groupId),
                  ),
                ),
              );
            },
          );
        },
      ),

      /// 🔘 FAB to Create Group
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
          );
        },
        child: const Icon(Icons.group_add),
        tooltip: 'Create Group',
      ),
    );
  }
}