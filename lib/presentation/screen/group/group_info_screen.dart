import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class GroupInfoScreen extends StatefulWidget {
  final String groupId;

  const GroupInfoScreen({super.key, required this.groupId});

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  DocumentSnapshot? groupDoc;

  @override
  void initState() {
    super.initState();
    fetchGroupDetails();
  }

  Future<void> fetchGroupDetails() async {
    final doc = await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .get();
    if (doc.exists) {
      setState(() => groupDoc = doc);
    }
  }

  Future<void> removeParticipant(String uid) async {
    final groupRef = FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId);
    await groupRef.update({
      'members': FieldValue.arrayRemove([uid]),
      'admins': FieldValue.arrayRemove([uid]),
    });
    fetchGroupDetails();
  }

  Future<void> toggleAdmin(String uid, bool isCurrentlyAdmin) async {
    final groupRef = FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId);
    await groupRef.update({
      'admins': isCurrentlyAdmin
          ? FieldValue.arrayRemove([uid])
          : FieldValue.arrayUnion([uid]),
    });
    fetchGroupDetails();
  }

  Future<void> leaveGroup() async {
    final groupRef = FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId);
    await groupRef.update({
      'members': FieldValue.arrayRemove([currentUser.uid]),
      'admins': FieldValue.arrayRemove([currentUser.uid]),
    });

    final updatedDoc = await groupRef.get();
    final updatedMembers = List<String>.from(updatedDoc['members'] ?? []);
    if (updatedMembers.isEmpty) {
      await groupRef.delete();
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('You left the group')));
    }
  }

  void goToAddParticipantScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PlaceholderScreen()),
    ).then((_) => fetchGroupDetails());
  }

  void _showParticipantOptions(
    String uid,
    String name,
    bool isParticipantAdmin,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (!isParticipantAdmin)
                ListTile(
                  leading: const Icon(
                    Icons.admin_panel_settings,
                    color: Colors.green,
                  ),
                  title: const Text('Promote to Admin'),
                  onTap: () {
                    Navigator.pop(context);
                    toggleAdmin(uid, false);
                  },
                ),
              if (isParticipantAdmin)
                ListTile(
                  leading: const Icon(
                    Icons.remove_moderator,
                    color: Colors.orange,
                  ),
                  title: const Text('Demote from Admin'),
                  onTap: () {
                    Navigator.pop(context);
                    toggleAdmin(uid, true);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.person_remove, color: Colors.red),
                title: const Text('Remove Participant'),
                onTap: () {
                  Navigator.pop(context);
                  _showRemoveConfirmation(uid, name);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showRemoveConfirmation(String uid, String name) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Participant'),
          content: Text(
            'Are you sure you want to remove $name from the group?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                removeParticipant(uid);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$name removed from group')),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (groupDoc == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final groupData = groupDoc!.data() as Map<String, dynamic>;
    final members = List<String>.from(groupData['members'] ?? []);
    final admins = List<String>.from(groupData['admins'] ?? []);
    final isAdmin = admins.contains(currentUser.uid);

    return Scaffold(
      appBar: AppBar(title: const Text('Group Info')),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: goToAddParticipantScreen,
              child: const Icon(Icons.person_add),
            )
          : null,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                // Group Info Header
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: groupData['groupImageUrl'] != null
                            ? NetworkImage(groupData['groupImageUrl'])
                            : null,
                        child: groupData['groupImageUrl'] == null
                            ? const Icon(Icons.group, size: 40)
                            : null,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        groupData['groupName'] ?? 'Group',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (groupData['groupDescription'] != null) ...[
                        const SizedBox(height: 6),
                        Text(groupData['groupDescription']),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Participants Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Participants (${members.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const Divider(),

                // Participants List
                ...members.map((uid) {
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return const SizedBox();
                      }

                      final userData =
                          snapshot.data!.data() as Map<String, dynamic>;
                      final name = userData['name'] ?? 'User';
                      final email = userData['email'] ?? '';
                      final isParticipantAdmin = admins.contains(uid);

                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: userData['profileImage'] != null
                                ? NetworkImage(userData['profileImage'])
                                : null,
                            child: userData['profileImage'] == null
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Row(
                            children: [
                              Expanded(child: Text(name)),
                              if (isParticipantAdmin)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Admin',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Text(email),
                          trailing: uid == currentUser.uid
                              ? const Text(
                                  "You",
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : isAdmin
                              ? IconButton(
                                  icon: const Icon(Icons.more_vert),
                                  onPressed: () => _showParticipantOptions(
                                    uid,
                                    name,
                                    isParticipantAdmin,
                                  ),
                                )
                              : null,
                        ),
                      );
                    },
                  );
                }),

                const SizedBox(height: 20),
              ],
            ),
          ),

          const Divider(),

          // Leave Group Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: ElevatedButton.icon(
              onPressed: leaveGroup,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                minimumSize: const Size(double.infinity, 48),
              ),
              icon: const Icon(Icons.exit_to_app),
              label: const Text('Leave Group'),
            ),
          ),

          // Delete Group if Admin
          if (isAdmin)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: TextButton.icon(
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('groups')
                      .doc(widget.groupId)
                      .delete();
                  if (mounted) Navigator.pop(context);
                },
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                label: const Text(
                  'Delete Group',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Participants")),
      body: const Center(child: Text("Coming Soon")),
    );
  }
}
