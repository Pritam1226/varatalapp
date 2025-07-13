import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:intl/intl.dart';

// import 'addcontact_screen.dart';
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
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) =>
                        _searchQuery.value = value.toLowerCase(),
                    decoration: InputDecoration(
                      hintText: 'Search contacts or messages...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: ValueListenableBuilder<String>(
                        valueListenable: _searchQuery,
                        builder: (context, value, _) {
                          return value.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    _searchQuery.value = '';
                                  },
                                )
                              : const SizedBox.shrink();
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ValueListenableBuilder<String>(
                    valueListenable: _searchQuery,
                    builder: (context, query, _) {
                      return FutureBuilder<List<DocumentSnapshot>>(
                        future: _fetchFilteredChats(currentUserId, query),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: Text('Error: ${snapshot.error}'),
                            );
                          }
                          final filteredDocs = snapshot.data ?? [];
                          if (filteredDocs.isEmpty) {
                            return const Center(
                              child: Text(
                                'No results found',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            itemCount: filteredDocs.length,
                            itemBuilder: (context, idx) {
                              final doc = filteredDocs[idx];
                              final chatId = doc.id;
                              final data = doc.data() as Map<String, dynamic>;
                              final users = List<String>.from(
                                data['users'] ?? [],
                              );
                              final otherId = users.firstWhere(
                                (uid) => uid != currentUserId,
                                orElse: () => '',
                              );

                              String contactName = 'Contact';
                              String? profileImageUrl;
                              if (data.containsKey('contactNames')) {
                                final names = Map<String, dynamic>.from(
                                  data['contactNames'],
                                );
                                contactName = names[otherId] ?? contactName;
                              }
                              if (data.containsKey('contactProfileImages')) {
                                final imgs = Map<String, dynamic>.from(
                                  data['contactProfileImages'],
                                );
                                profileImageUrl = imgs[otherId];
                              }

                              final lastMsg = data['lastMessage'] ?? '';
                              final time =
                                  data['lastMessageTime'] as Timestamp?;
                              final timeStr = time != null
                                  ? formatTime(time)
                                  : '';

                              return Dismissible(
                                key: Key(chatId),
                                background: _buildSwipeActionLeft(),
                                secondaryBackground: _buildSwipeActionRight(),
                                confirmDismiss: (direction) async {
                                  if (direction ==
                                      DismissDirection.endToStart) {
                                    final confirm = await _showConfirmDialog(
                                      context,
                                      'Delete this chat?',
                                    );
                                    if (confirm) {
                                      await FirebaseFirestore.instance
                                          .collection('chats')
                                          .doc(chatId)
                                          .delete();
                                    }
                                    return confirm;
                                  } else if (direction ==
                                      DismissDirection.startToEnd) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('$contactName archived'),
                                      ),
                                    );
                                    return false;
                                  }
                                  return false;
                                },
                                child: ListTile(
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
                                    child: CircleAvatar(
                                      backgroundImage: profileImageUrl != null
                                          ? NetworkImage(profileImageUrl)
                                          : null,
                                      child: profileImageUrl == null
                                          ? const Icon(Icons.person)
                                          : null,
                                    ),
                                  ),
                                  title: Text(contactName),
                                  subtitle: Text(
                                    lastMsg.isNotEmpty
                                        ? lastMsg
                                        : 'Start a chat…',
                                    style: TextStyle(
                                      fontStyle: lastMsg.isEmpty
                                          ? FontStyle.italic
                                          : null,
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
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0, top: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: () {},
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color.fromARGB(255, 38, 150, 255),
                                    const Color.fromARGB(255, 30, 91, 244),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.remove_red_eye,
                                    color: Colors.white,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'View Status',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: () {},
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color.fromARGB(255, 38, 150, 255),
                                    const Color.fromARGB(255, 30, 91, 244),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.history, color: Colors.white),
                                  SizedBox(height: 4),
                                  Text(
                                    'My Status',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

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

    final matchedDocs = <DocumentSnapshot>[];

    for (final doc in chatSnap.docs) {
      final data = doc.data();
      final users = List<String>.from(data['users'] ?? []);
      final otherId = users.firstWhere(
        (uid) => uid != currentUserId,
        orElse: () => '',
      );
      final contactNames = Map<String, dynamic>.from(
        data['contactNames'] ?? {},
      );
      final name = contactNames[otherId]?.toString().toLowerCase() ?? '';

      final lastMessage = (data['lastMessage'] ?? '').toString().toLowerCase();

      if (name.contains(queryLower) || lastMessage.contains(queryLower)) {
        matchedDocs.add(doc);
        continue;
      }

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

      if (hasMatch) {
        matchedDocs.add(doc);
      }
    }

    return matchedDocs;
  }

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
