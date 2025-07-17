import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:varatalapp/presentation/screen/group/group_info_screen.dart'; // ✅ Make sure this path is correct

class GroupChatScreen extends StatefulWidget {
  final String groupId;

  const GroupChatScreen({super.key, required this.groupId});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<String> _participants = [];

  @override
  void initState() {
    super.initState();
    _fetchParticipants();
  }

  Future<void> _fetchParticipants() async {
    final groupSnapshot = await _firestore
        .collection('groups')
        .doc(widget.groupId)
        .get();
    final participants = List<String>.from(
      groupSnapshot.data()?['participants'] ?? [],
    );
    setState(() {
      _participants = participants;
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final userSnapshot = await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .get();
    final senderName = userSnapshot.data()?['name'] ?? 'User';

    final readStatus = {
      for (var uid in _participants) uid: uid == currentUser.uid,
    };

    final messageData = {
      'senderId': currentUser.uid,
      'senderName': senderName,
      'text': message,
      'timestamp': FieldValue.serverTimestamp(),
      'readBy': readStatus,
    };

    try {
      await _firestore
          .collection('groups')
          .doc(widget.groupId)
          .collection('messages')
          .add(messageData);
      await _firestore.collection('groups').doc(widget.groupId).update({
        'lastMessage': message,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
      _messageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to send message. Please try again."),
        ),
      );
    }
  }

  Future<void> _markAsRead(DocumentSnapshot msg) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final msgData = msg.data() as Map<String, dynamic>;
    final readBy = Map<String, dynamic>.from(msgData['readBy'] ?? {});

    if (readBy[currentUser.uid] != true) {
      readBy[currentUser.uid] = true;
      await msg.reference.update({'readBy': readBy});
    }
  }

  bool _isMessageReadByAll(Map<String, dynamic> readBy) {
    return _participants.isNotEmpty &&
        _participants.every((uid) => readBy[uid] == true);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("User not logged in")));
    }

    final messagesRef = _firestore
        .collection('groups')
        .doc(widget.groupId)
        .collection('messages')
        .orderBy('timestamp', descending: true);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 93, 153, 232),
        title: StreamBuilder<DocumentSnapshot>(
          stream: _firestore
              .collection('groups')
              .doc(widget.groupId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Text("Group Chat");
            }
            final groupData = snapshot.data!.data() as Map<String, dynamic>;
            final groupName = groupData['groupName'] ?? 'Group Chat';
            final groupImage = groupData['groupIcon'] ?? '';

            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        GroupInfoScreen(groupId: widget.groupId),
                  ),
                );
              },
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: groupImage.isNotEmpty
                        ? NetworkImage(groupImage)
                        : null,
                    child: groupImage.isEmpty ? const Icon(Icons.group) : null,
                    radius: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      groupName,
                      style: const TextStyle(fontSize: 18),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: messagesRef.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text("Something went wrong"));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No messages yet."));
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final data = msg.data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == currentUser.uid;
                    final readBy = Map<String, dynamic>.from(
                      data['readBy'] ?? {},
                    );

                    if (!isMe) _markAsRead(msg);

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth:
                                MediaQuery.of(context).size.width *
                                0.7, // 70% width
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? const Color.fromARGB(255, 87, 151, 234)
                                  : Colors.grey[300],
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(12),
                                topRight: const Radius.circular(12),
                                bottomLeft: isMe
                                    ? const Radius.circular(12)
                                    : Radius.zero,
                                bottomRight: isMe
                                    ? Radius.zero
                                    : const Radius.circular(12),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isMe)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      data['senderName'] ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                Text(
                                  data['text'] ?? '',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: isMe ? Colors.white : Colors.black,
                                  ),
                                ),
                                if (isMe)
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Icon(
                                        _isMessageReadByAll(readBy)
                                            ? Icons.done_all
                                            : Icons.done,
                                        size: 16,
                                        color: _isMessageReadByAll(readBy)
                                            ? const Color.fromARGB(
                                                255,
                                                75,
                                                225,
                                                110,
                                              )
                                            : Colors.white70,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: () {
                    // TODO: Handle file/image attachments
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.camera_alt),
                  onPressed: () {
                    // TODO: Handle camera picker
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.all(10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                  color: const Color.fromARGB(255, 46, 109, 218),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
