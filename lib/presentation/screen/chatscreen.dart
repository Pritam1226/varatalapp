import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  final String contactName;
  final String contactId;

  const ChatScreen({
    Key? key,
    required this.contactName,
    required this.contactId, String? scrollToMessageId,
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
  String _searchQuery = '';  // 🔄 Added

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
    final chatDoc =
        await FirebaseFirestore.instance.collection('chats').doc(chatId).get();

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
      'timestamp': timestamp,
    };

    final chatDoc =
        FirebaseFirestore.instance.collection('chats').doc(chatId);

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
      'contactNames': {
        senderId: currentUserName,
        receiverId: receiverName,
      },
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

  void _handleMenuAction(String value) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final chatId = _chatId(currentUser!.uid, widget.contactId);
    final chatDoc =
        FirebaseFirestore.instance.collection('chats').doc(chatId);

    switch (value) {
      case 'view':
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Contact Info'),
            content: Text('Name: ${widget.contactName}\nUID: ${widget.contactId}'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context), child: const Text("Close"))
            ],
          ),
        );
        break;

      case 'unpin':
        await chatDoc.set({'pinnedMessage': FieldValue.delete()}, SetOptions(merge: true));
        setState(() => _pinnedMessage = null);
        break;

      case 'block':
        await chatDoc.set({
          'blockedBy': FieldValue.arrayUnion([currentUser.uid])
        }, SetOptions(merge: true));
        setState(() => _isBlocked = true);
        break;

      case 'unblock':
        await chatDoc.set({
          'blockedBy': FieldValue.arrayRemove([currentUser.uid])
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
    final chatDoc =
        FirebaseFirestore.instance.collection('chats').doc(chatId);

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
            ? Text(widget.contactName)
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
                const PopupMenuItem(value: 'unpin', child: Text('Unpin Message')),
              PopupMenuItem(
                value: _isBlocked ? 'unblock' : 'block',
                child: Text(_isBlocked ? 'Unblock Contact' : 'Block Contact'),
              ),
              const PopupMenuItem(value: 'wallpaper', child: Text('Change Wallpaper')),
            ],
          )
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
                      : allDocs
                          .where((doc) {
                            final text = (doc.data() as Map<String, dynamic>)['text'] ?? '';
                            return text.toLowerCase().contains(_searchQuery.toLowerCase());
                          })
                          .toList();

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
                          ? TimeOfDay.fromDateTime(timestamp.toDate())
                              .format(context)
                          : '';

                      return GestureDetector(
                        onLongPress: () {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Pin Message?'),
                              content: Text(m['text'] ?? ''),
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
                                Text(
                                  timeStr,
                                  style: TextStyle(
                                      fontSize: 10, color: Colors.grey[700]),
                                ),
                              ],
                            ),
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
                  child: Text("typing...",
                      style: TextStyle(
                          fontStyle: FontStyle.italic, color: Colors.grey)),
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
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _isBlocked ? null : _sendMessage,
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
