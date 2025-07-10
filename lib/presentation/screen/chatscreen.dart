import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  final String contactName;
  final String contactId;

  const ChatScreen({
    Key? key,
    required this.contactName,
    required this.contactId,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  /// build a stable chat‑id from two uids
  String _chatId(String uid1, String uid2) =>
      (uid1.compareTo(uid2) < 0) ? '${uid1}_$uid2' : '${uid2}_$uid1';

  /// send a message and update last‑message fields
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final senderId = currentUser.uid;
    final receiverId = widget.contactId;
    final chatId = _chatId(senderId, receiverId);

    final timestamp = FieldValue.serverTimestamp();

    final msgData = {
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp,
    };

    final chatDoc = FirebaseFirestore.instance.collection('chats').doc(chatId);

    // 1️⃣ add message
    await chatDoc.collection('messages').add(msgData);

    // 2️⃣ set / update chat summary (users + lastMessage)
    await chatDoc.set({
      'users': [senderId, receiverId],      // participants array
      'lastMessage': text,
      'lastMessageTime': timestamp,
    }, SetOptions(merge: true));

    // clear UI
    _messageController.clear();
    setState(() => _isTyping = false);

    // scroll to bottom after a short delay
    await Future.delayed(const Duration(milliseconds: 150));
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;
    final chatId = _chatId(currentUid, widget.contactId);

    return Scaffold(
      appBar: AppBar(title: Text(widget.contactName)),
      body: Column(
        children: [
          /// 📨 messages list (reverse = newest at bottom)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snap.data!.docs;

                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  itemCount: docs.length,
                  itemBuilder: (_, idx) {
                    final m = docs[idx];
                    final isMe = m['senderId'] == currentUid;
                    final timeStamp = m['timestamp'] as Timestamp?;
                    final timeStr = timeStamp != null
                        ? TimeOfDay.fromDateTime(timeStamp.toDate())
                            .format(context)
                        : '';

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue[200] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(m['text'] ?? '',
                                style: const TextStyle(fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(timeStr,
                                style: TextStyle(
                                    fontSize: 10, color: Colors.grey[700])),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          /// 🔤 typing indicator
          if (_isTyping)
            const Padding(
              padding: EdgeInsets.only(left: 16.0, bottom: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("typing...",
                    style:
                        TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
              ),
            ),

          /// 📤 input row
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: () {}, // TODO: file picker
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: "Type a message…",
                      border: InputBorder.none,
                    ),
                    onChanged: (val) =>
                        setState(() => _isTyping = val.isNotEmpty),
                  ),
                ),
                IconButton(icon: const Icon(Icons.send), onPressed: _sendMessage),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
