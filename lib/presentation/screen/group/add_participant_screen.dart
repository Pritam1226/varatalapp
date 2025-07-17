import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddParticipantScreen extends StatefulWidget {
  final String groupId;
  final List<String> currentMembers;

  const AddParticipantScreen({
    Key? key,
    required this.groupId,
    required this.currentMembers,
  }) : super(key: key);

  @override
  State<AddParticipantScreen> createState() => _AddParticipantScreenState();
}

class _AddParticipantScreenState extends State<AddParticipantScreen> {
  List<String> selectedUserIds = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Participants"),
        actions: [
          TextButton(
            onPressed: selectedUserIds.isEmpty ? null : _addParticipants,
            child: const Text("ADD", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final users = snapshot.data!.docs
              .where((doc) => !widget.currentMembers.contains(doc.id))
              .toList();

          if (users.isEmpty) {
            return const Center(child: Text('No users available to add.'));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final userData = user.data() as Map<String, dynamic>;
              final isSelected = selectedUserIds.contains(user.id);

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: userData['profileImage'] != null
                      ? NetworkImage(userData['profileImage'])
                      : null,
                  child: userData['profileImage'] == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text(userData['name'] ?? 'Unknown'),
                subtitle: Text(userData['email'] ?? ''),
                trailing: Checkbox(
                  value: isSelected,
                  onChanged: (selected) {
                    setState(() {
                      if (selected == true) {
                        selectedUserIds.add(user.id);
                      } else {
                        selectedUserIds.remove(user.id);
                      }
                    });
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _addParticipants() async {
    final groupRef = FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId);
    await groupRef.update({'members': FieldValue.arrayUnion(selectedUserIds)});
    Navigator.pop(context); // Go back to GroupInfoScreen
  }
}
