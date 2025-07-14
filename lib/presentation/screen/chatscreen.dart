import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'chat_widgets/voice_recorder.dart';
import 'contact/contact_profile_popup.dart';
// import 'ProfileView.dart';

class ChatScreen extends StatefulWidget {
  final String contactName;
  final String contactId;

  const ChatScreen({
    Key? key,
    required this.contactName,
    required this.contactId,
    String? scrollToMessageId,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isTyping = false;
  bool _isBlocked = false;
  Map<String, dynamic>? _pinnedMessage;
  String? _wallpaperUrl;

  bool _isSearching = false; // 🔄 Added
  String _searchQuery = ''; // 🔄 Added

  String _chatId(String uid1, String uid2) =>
      (uid1.compareTo(uid2) < 0) ? '${uid1}_$uid2' : '${uid2}_$uid1';

  @override
  void initState() {
    super.initState();
    _loadChatSettings();
  }

  Future<void> _loadChatSettings() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final chatId = _chatId(currentUser.uid, widget.contactId);
    final chatDoc = await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .get();

    final data = chatDoc.data();
    if (data != null) {
      setState(() {
        _isBlocked = (data['blockedBy'] ?? []).contains(currentUser.uid);
        _pinnedMessage = data['pinnedMessage'];
        _wallpaperUrl = data['wallpaperUrl'];
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isBlocked) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final senderId = currentUser.uid;
    final receiverId = widget.contactId;
    final chatId = _chatId(senderId, receiverId);
    final timestamp = FieldValue.serverTimestamp();

    final msgData = {
      'senderId': senderId,
      'text': text,
      'type': 'text',
      'timestamp': timestamp,
    };

    final chatDoc = FirebaseFirestore.instance.collection('chats').doc(chatId);

    await chatDoc.collection('messages').add(msgData);

    final senderSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(senderId)
        .get();
    final currentUserName = senderSnapshot.data()?['name'] ?? 'Unknown';

    final receiverSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(receiverId)
        .get();
    final receiverName = receiverSnapshot.data()?['name'] ?? 'Contact';

    await chatDoc.set({
      'users': [senderId, receiverId],
      'lastMessage': text,
      'lastMessageTime': timestamp,
      'contactNames': {senderId: currentUserName, receiverId: receiverName},
    }, SetOptions(merge: true));

    _messageController.clear();
    setState(() => _isTyping = false);

    await Future.delayed(const Duration(milliseconds: 150));
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendVoiceMessage(String url, double duration) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final senderId = currentUser.uid;
    final receiverId = widget.contactId;
    final chatId = _chatId(senderId, receiverId);
    final timestamp = FieldValue.serverTimestamp();

    final senderSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(senderId)
        .get();
    final receiverSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(receiverId)
        .get();

    final currentUserName = senderSnapshot.data()?['name'] ?? 'Unknown';
    final receiverName = receiverSnapshot.data()?['name'] ?? 'Contact';

    final messageData = {
      'type': 'audio',
      'audioUrl': url,
      'duration': duration,
      'senderId': senderId,
      'timestamp': timestamp,
    };

    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);
    await chatRef.collection('messages').add(messageData);
    await chatRef.set({
      'users': [senderId, receiverId],
      'lastMessage': '[Voice]',
      'lastMessageTime': timestamp,
      'contactNames': {senderId: currentUserName, receiverId: receiverName},
    }, SetOptions(merge: true));
  }

  void _handleMenuAction(String value) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final chatId = _chatId(currentUser!.uid, widget.contactId);
    final chatDoc = FirebaseFirestore.instance.collection('chats').doc(chatId);

    switch (value) {
      case 'view':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ContactProfilePopup(
              contactName: widget.contactName,
              contactId: widget.contactId,
            ),
          ),
        );
        break;

      case 'unpin':
        await chatDoc.set({
          'pinnedMessage': FieldValue.delete(),
        }, SetOptions(merge: true));
        setState(() => _pinnedMessage = null);
        break;

      case 'block':
        await chatDoc.set({
          'blockedBy': FieldValue.arrayUnion([currentUser.uid]),
        }, SetOptions(merge: true));
        setState(() => _isBlocked = true);
        break;

      case 'unblock':
        await chatDoc.set({
          'blockedBy': FieldValue.arrayRemove([currentUser.uid]),
        }, SetOptions(merge: true));
        setState(() => _isBlocked = false);
        break;

      case 'wallpaper':
        final randomUrl = 'https://source.unsplash.com/random/800x600';
        await chatDoc.set({'wallpaperUrl': randomUrl}, SetOptions(merge: true));
        setState(() => _wallpaperUrl = randomUrl);
        break;
    }
  }

  Future<void> _pinMessage(Map<String, dynamic> message) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final chatId = _chatId(currentUser!.uid, widget.contactId);
    final chatDoc = FirebaseFirestore.instance.collection('chats').doc(chatId);

    await chatDoc.set({'pinnedMessage': message}, SetOptions(merge: true));
    setState(() => _pinnedMessage = message);
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
      appBar: AppBar(
        title: !_isSearching
            ? Row(
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ContactProfilePopup(
                            contactName: widget.contactName,
                            contactId: widget.contactId,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(50),
                    child: CircleAvatar(
                      radius:
                          20, // Made it slightly larger for better visibility
                      backgroundColor: Colors.grey.shade300,
                      child: const Icon(
                        Icons.person,
                        size: 22,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.contactName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              )
            : TextField(
                autofocus: true,
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                decoration: const InputDecoration(
                  hintText: 'Search messages...',
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: Colors.white),
              ),

        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchQuery = '';
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'view', child: Text('View Contact')),
              if (_pinnedMessage != null)
                const PopupMenuItem(
                  value: 'unpin',
                  child: Text('Unpin Message'),
                ),
              PopupMenuItem(
                value: _isBlocked ? 'unblock' : 'block',
                child: Text(_isBlocked ? 'Unblock Contact' : 'Block Contact'),
              ),
              const PopupMenuItem(
                value: 'wallpaper',
                child: Text('Change Wallpaper'),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: _wallpaperUrl != null
            ? BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(_wallpaperUrl!),
                  fit: BoxFit.cover,
                ),
              )
            : null,
        child: Column(
          children: [
            if (_pinnedMessage != null)
              Container(
                width: double.infinity,
                color: Colors.yellow[100],
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    const Icon(Icons.push_pin, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _pinnedMessage?['text'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .doc(chatId)
                    .collection('messages')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snap.hasError) {
                    return const Center(child: Text('Error loading messages'));
                  }

                  final allDocs = snap.data?.docs ?? [];
                  final docs = _searchQuery.isEmpty
                      ? allDocs
                      : allDocs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final text = data['text'] ?? '';
                          return text.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          );
                        }).toList();

                  if (docs.isEmpty) {
                    return const Center(child: Text('No messages found.'));
                  }

                  return ListView.builder(
                    reverse: true,
                    controller: _scrollController,
                    itemCount: docs.length,
                    itemBuilder: (_, idx) {
                      final m = docs[idx].data() as Map<String, dynamic>;
                      final isMe = m['senderId'] == currentUid;
                      final timestamp = m['timestamp'];
                      final timeStr = (timestamp is Timestamp)
                          ? TimeOfDay.fromDateTime(
                              timestamp.toDate(),
                            ).format(context)
                          : '';

                      Widget content;
                      if (m['type'] == 'audio') {
                        content = Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.play_arrow),
                                const SizedBox(width: 8),
                                Text('${m['duration'].toStringAsFixed(1)} sec'),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              timeStr,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        );
                      } else {
                        content = Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              m['text'] ?? '',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              timeStr,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        );
                      }

                      return GestureDetector(
                        onLongPress: () {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Pin Message?'),
                              content: Text(m['text'] ?? '[Audio Message]'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _pinMessage(m);
                                  },
                                  child: const Text('PIN'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('CANCEL'),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 10,
                            ),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.blue[200] : Colors.grey[300],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: content,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            if (_isTyping)
              const Padding(
                padding: EdgeInsets.only(left: 16.0, bottom: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "typing...",
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: () {},
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      enabled: !_isBlocked,
                      decoration: InputDecoration(
                        hintText: _isBlocked
                            ? "You have blocked this contact"
                            : "Type a message…",
                        border: InputBorder.none,
                      ),
                      onChanged: (val) =>
                          setState(() => _isTyping = val.trim().isNotEmpty),
                    ),
                  ),
                  if (_isTyping)
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _isBlocked ? null : _sendMessage,
                    )
                  else
                    VoiceRecorder(
                      onSend: _isBlocked ? (_, __) {} : _sendVoiceMessage,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
