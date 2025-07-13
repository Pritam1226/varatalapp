import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'chatscreen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'package:varatalapp/presentation/screen/contact/contact_profile_popup.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<String> _searchQuery = ValueNotifier('');

  String formatTime(Timestamp timestamp) =>
      DateFormat('hh:mm a').format(timestamp.toDate());

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vartalap'),
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
                  break;
                case 'settings':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                  break;
                case 'logout':
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.popUntil(context, (r) => r.isFirst);
                  }
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
          : Column(
              children: [
                // ─── SEARCH BAR ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) =>
                        _searchQuery.value = value.toLowerCase(),
                    decoration: InputDecoration(
                      hintText: 'Search contacts or messages…',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: ValueListenableBuilder<String>(
                        valueListenable: _searchQuery,
                        builder: (context, value, _) => value.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _searchQuery.value = '';
                                },
                              )
                            : const SizedBox.shrink(),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                // ─── CHAT LIST ──────────────────────────────────────────────
                Expanded(
                  child: ValueListenableBuilder<String>(
                    valueListenable: _searchQuery,
                    builder: (context, query, _) {
                      return FutureBuilder<List<DocumentSnapshot>>(
                        future: _fetchFilteredChats(currentUserId, query),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Center(child: Text('Error: ${snapshot.error}'));
                          }
                          final docs = snapshot.data ?? [];
                          if (docs.isEmpty) {
                            return const Center(
                              child: Text(
                                'No results found',
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            );
                          }
                          return ListView.builder(
                            itemCount: docs.length,
                            itemBuilder: (context, idx) {
                              final doc = docs[idx];
                              final chatId = doc.id;
                              final data = doc.data() as Map<String, dynamic>;
                              final users = List<String>.from(data['users'] ?? []);
                              final otherId =
                                  users.firstWhere((u) => u != currentUserId, orElse: () => '');

                              // name & avatar
                              String contactName = 'Contact';
                              String? profileImageUrl;
                              if (data.containsKey('contactNames')) {
                                final names = Map<String, dynamic>.from(data['contactNames']);
                                contactName = names[otherId] ?? contactName;
                              }
                              if (data.containsKey('contactProfileImages')) {
                                final imgs = Map<String, dynamic>.from(data['contactProfileImages']);
                                profileImageUrl = imgs[otherId];
                              }

                              // last message & time
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
                                      await FirebaseFirestore.instance
                                          .collection('chats')
                                          .doc(chatId)
                                          .delete();
                                    }
                                    return confirm;
                                  } else if (direction == DismissDirection.startToEnd) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('$contactName archived')),
                                    );
                                    return false; // archive is only visual here
                                  }
                                  return false;
                                },
                                child: ListTile(
                                  // ─── AVATAR WITH ONLINE DOT ────────────
                                  leading: GestureDetector(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => ContactProfilePopup(
                                          contactId: otherId,
                                          contactName: contactName,
                                          profileImageUrl: profileImageUrl,
                                        ),
                                      );
                                    },
                                    child: Stack(
                                      children: [
                                        CircleAvatar(
                                          radius: 25,
                                          backgroundImage: profileImageUrl != null
                                              ? NetworkImage(profileImageUrl)
                                              : null,
                                          child: profileImageUrl == null
                                              ? const Icon(Icons.person)
                                              : null,
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: StreamBuilder<DocumentSnapshot>(
                                            stream: FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(otherId)
                                                .snapshots(),
                                            builder: (context, snap) {
                                              bool isOnline = false;
                                              if (snap.hasData && snap.data!.data() != null) {
                                                final user = snap.data!.data() as Map<String, dynamic>;
                                                isOnline = user['isOnline'] == true;
                                              }
                                              return Container(
                                                width: 12,
                                                height: 12,
                                                decoration: BoxDecoration(
                                                  color: isOnline ? Colors.green : Colors.grey,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: Colors.white, width: 2),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // ─── NAME, LAST MSG, TIME ──────────────
                                  title: Text(contactName),
                                  subtitle: Text(
                                    lastMsg.isNotEmpty ? lastMsg : 'Start a chat…',
                                    style: TextStyle(
                                      fontStyle: lastMsg.isEmpty ? FontStyle.italic : null,
                                    ),
                                  ),
                                  trailing: Text(timeStr),
                                  // ─── TAP TO OPEN CHAT ───────────────────
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ChatScreen(contactName: contactName, contactId: otherId),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
                // ─── STATUS SHORTCUTS (UNCHANGED) ──────────────────────────
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0, top: 8.0),
                  child: Row(
                    children: [
                      Expanded(child: _statusButton('View Status', Icons.remove_red_eye)),
                      const SizedBox(width: 12),
                      Expanded(child: _statusButton('My Status', Icons.history)),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ────────────────────────────────────────────────────────────────────────────

  Future<List<DocumentSnapshot>> _fetchFilteredChats(
    String currentUserId,
    String query,
  ) async {
    final queryLower = query.toLowerCase();
    final chatSnap = await FirebaseFirestore.instance
        .collection('chats')
        .where('users', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .get();

    final matched = <DocumentSnapshot>[];

    for (final doc in chatSnap.docs) {
      final data = doc.data();
      final users = List<String>.from(data['users'] ?? []);
      final otherId = users.firstWhere((u) => u != currentUserId, orElse: () => '');
      final contactNames = Map<String, dynamic>.from(data['contactNames'] ?? {});
      final name = contactNames[otherId]?.toString().toLowerCase() ?? '';
      final lastMessage = (data['lastMessage'] ?? '').toString().toLowerCase();

      if (name.contains(queryLower) || lastMessage.contains(queryLower)) {
        matched.add(doc);
        continue;
      }

      // deep search inside messages
      final msgSnap = await FirebaseFirestore.instance
          .collection('chats')
          .doc(doc.id)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .get();

      final hasMatch = msgSnap.docs.any((m) {
        final text = (m['text'] ?? '').toString().toLowerCase();
        return text.contains(queryLower);
      });

      if (hasMatch) matched.add(doc);
    }
    return matched;
  }

  Widget _buildSwipeActionLeft() => Container(
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

  Widget _buildSwipeActionRight() => Container(
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

  // small helper for status shortcut cards
  Widget _statusButton(String label, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color.fromARGB(255, 38, 150, 255),
                Color.fromARGB(255, 30, 91, 244),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
