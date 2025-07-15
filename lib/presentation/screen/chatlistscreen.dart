import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:varatalapp/presentation/screen/addcontact_screen.dart';
import 'package:varatalapp/presentation/screen/contact/profile_detail_screen.dart';
import 'chatscreen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

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
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: _handleCameraCapture,
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'profile':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                  break;
                case 'settings':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                  break;
                case 'add_contact':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddContactScreen()),
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
              PopupMenuItem(value: 'settings', child: Text('Settings')),
              PopupMenuItem(value: 'add_contact', child: Text('Add Contact')),
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
                Expanded(
                  child: ValueListenableBuilder<String>(
                    valueListenable: _searchQuery,
                    builder: (context, query, _) {
                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('chats')
                            .where('users', arrayContains: currentUserId)
                            .orderBy('lastMessageTime', descending: true)
                            .snapshots(),
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

                          var docs = snapshot.data?.docs ?? [];

                          if (query.isNotEmpty) {
                            docs = docs.where((d) {
                              final data = d.data() as Map<String, dynamic>;
                              final users = List<String>.from(
                                data['users'] ?? [],
                              );
                              final otherId = users.firstWhere(
                                (u) => u != currentUserId,
                                orElse: () => '',
                              );
                              final names = Map<String, dynamic>.from(
                                data['contactNames'] ?? {},
                              );
                              final name = (names[otherId] ?? '')
                                  .toString()
                                  .toLowerCase();
                              final lastMsg = (data['lastMessage'] ?? '')
                                  .toString()
                                  .toLowerCase();
                              return name.contains(query) ||
                                  lastMsg.contains(query);
                            }).toList();
                          }

                          if (docs.isEmpty) {
                            return const Center(
                              child: Text(
                                'No chats found',
                                style: TextStyle(color: Colors.grey),
                              ),
                            );
                          }

                          return ListView.builder(
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final doc = docs[index];
                              final data = doc.data() as Map<String, dynamic>;
                              final users = List<String>.from(
                                data['users'] ?? [],
                              );
                              final otherId = users.firstWhere(
                                (u) => u != currentUserId,
                                orElse: () => '',
                              );

                              final names = Map<String, dynamic>.from(
                                data['contactNames'] ?? {},
                              );
                              final contactName = names[otherId] ?? 'Contact';

                              final imgs = Map<String, dynamic>.from(
                                data['contactProfileImages'] ?? {},
                              );
                              final profileImageUrl = imgs[otherId];

                              final lastMsg = data['lastMessage'] ?? '';
                              final time =
                                  data['lastMessageTime'] as Timestamp?;
                              final timeStr = time != null
                                  ? formatTime(time)
                                  : '';

                              final isMuted = List<String>.from(
                                data['mutedBy'] ?? [],
                              ).contains(currentUserId);
                              final unreadCount =
                                  data['unreadCounts']?[currentUserId] ?? 0;

                              return ListTile(
                                leading: GestureDetector(
                                  onTap: () => _showQuickOptions(
                                    context,
                                    doc.id,
                                    contactName,
                                    otherId,
                                    profileImageUrl,
                                    isMuted,
                                  ),
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
                                            bool canShowOnline = false;

                                            if (snap.hasData &&
                                                snap.data!.data() != null) {
                                              final userData =
                                                  snap.data!.data()
                                                      as Map<String, dynamic>;

                                              isOnline =
                                                  userData['isOnline'] == true;

                                              final visibility =
                                                  (userData['showOnlineStatus'] ??
                                                          'everyone')
                                                      .toString()
                                                      .trim()
                                                      .toLowerCase();

                                              if (visibility == 'everyone') {
                                                canShowOnline = true;
                                              } else if (visibility ==
                                                  'my_contact') {
                                                // TODO: check if current user is in their contact list
                                                canShowOnline = true;
                                              } else {
                                                canShowOnline = false;
                                              }
                                            }

                                            return Container(
                                              width: 12,
                                              height: 12,
                                              decoration: BoxDecoration(
                                                color:
                                                    (isOnline && canShowOnline)
                                                    ? Colors.green
                                                    : Colors.grey,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 2,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
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
                                trailing: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          timeStr,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        const SizedBox(width: 4),
                                        if (isMuted)
                                          const Icon(
                                            Icons.volume_off,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    if (unreadCount > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          '$unreadCount',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatScreen(
                                      contactName: contactName,
                                      contactId: otherId,
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
              ],
            ),
    );
  }

  Future<void> _handleCameraCapture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera image captured! (Implement sharing logic)'),
        ),
      );
    }
  }

  void _showQuickOptions(
    BuildContext context,
    String chatId,
    String contactName,
    String contactId,
    String? profileImg,
    bool isMuted,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('Chat'),
              onTap: () {
                Navigator.pop(context);
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
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('View Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfileDetailScreen(contactId: contactId),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(isMuted ? Icons.volume_up : Icons.volume_off),
              title: Text(isMuted ? 'Unmute' : 'Mute'),
              onTap: () async {
                Navigator.pop(context);
                final uid = FirebaseAuth.instance.currentUser!.uid;
                final doc = FirebaseFirestore.instance
                    .collection('chats')
                    .doc(chatId);
                await doc.update({
                  'mutedBy': isMuted
                      ? FieldValue.arrayRemove([uid])
                      : FieldValue.arrayUnion([uid]),
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'Delete Chat',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                Navigator.pop(context);
                await FirebaseFirestore.instance
                    .collection('chats')
                    .doc(chatId)
                    .delete();
              },
            ),
          ],
        ),
      ),
    );
  }
}
