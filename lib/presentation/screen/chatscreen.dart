import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'chat_widgets/voice_recorder.dart';
import 'contact/profile_detail_screen.dart';

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

class _ChatScreenState extends State<ChatScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isTyping = false;
  bool _isBlocked = false;
  Map<String, dynamic>? _pinnedMessage;
  String? _wallpaperUrl;
  bool _isSearching = false;
  String _searchQuery = '';
  String _contactStatus = 'Offline';

  // Attachment-related variables
  bool _showAttachmentOptions = false;
  late AnimationController _attachmentAnimationController;
  late Animation<double> _attachmentAnimation;
  final ImagePicker _imagePicker = ImagePicker();

  String _chatId(String uid1, String uid2) =>
      (uid1.compareTo(uid2) < 0) ? '${uid1}_$uid2' : '${uid2}_$uid1';

  void _listenToContactStatus() {
    FirebaseFirestore.instance
        .collection('users')
        .doc(widget.contactId)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists) {
            final isOnline = snapshot.data()?['isOnline'] ?? false;
            setState(() => _contactStatus = isOnline ? 'Online' : 'Offline');
          }
        });
  }

  void _setUserOnline(bool isOnline) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({
            'isOnline': isOnline,
            if (!isOnline) 'lastSeen': FieldValue.serverTimestamp(),
          });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadChatSettings();
    _listenToContactStatus();
    WidgetsBinding.instance.addObserver(this);
    _setUserOnline(true);

    // Initialize animation controller for attachment options
    _attachmentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _attachmentAnimation = CurvedAnimation(
      parent: _attachmentAnimationController,
      curve: Curves.easeInOut,
    );
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
    final receiverSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(receiverId)
        .get();
    final currentUserName = senderSnapshot.data()?['name'] ?? 'Unknown';
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

  // New method to handle image selection
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      if (image != null) {
        // Here you would typically upload the image to Firebase Storage
        // and then send the image URL as a message
        await _sendMediaMessage(image.path, 'image');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    } finally {
      _toggleAttachmentOptions();
    }
  }

  // New method to handle video selection
  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
      );
      if (video != null) {
        // Here you would typically upload the video to Firebase Storage
        // and then send the video URL as a message
        await _sendMediaMessage(video.path, 'video');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking video: $e')));
    } finally {
      _toggleAttachmentOptions();
    }
  }

  // New method to handle file selection
  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null) {
        String filePath = result.files.single.path!;
        // Here you would typically upload the file to Firebase Storage
        // and then send the file URL as a message
        await _sendMediaMessage(filePath, 'file');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
    } finally {
      _toggleAttachmentOptions();
    }
  }

  // New method to send media messages
  Future<void> _sendMediaMessage(String filePath, String type) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final senderId = currentUser.uid;
    final receiverId = widget.contactId;
    final chatId = _chatId(senderId, receiverId);
    final timestamp = FieldValue.serverTimestamp();

    // In a real app, you would upload the file to Firebase Storage first
    // For now, we'll just send the local file path (this won't work in production)
    final messageData = {
      'type': type,
      'filePath': filePath,
      'senderId': senderId,
      'timestamp': timestamp,
    };

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

    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);
    await chatRef.collection('messages').add(messageData);

    String lastMessage = '[${type.capitalize()}]';
    await chatRef.set({
      'users': [senderId, receiverId],
      'lastMessage': lastMessage,
      'lastMessageTime': timestamp,
      'contactNames': {senderId: currentUserName, receiverId: receiverName},
    }, SetOptions(merge: true));
  }

  // Toggle attachment options visibility
  void _toggleAttachmentOptions() {
    setState(() {
      _showAttachmentOptions = !_showAttachmentOptions;
    });

    if (_showAttachmentOptions) {
      _attachmentAnimationController.forward();
    } else {
      _attachmentAnimationController.reverse();
    }
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
            builder: (_) => ProfileDetailScreen(contactId: widget.contactId),
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
    _attachmentAnimationController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _setUserOnline(false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _setUserOnline(true);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _setUserOnline(false);
    }
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
                          builder: (_) =>
                              ProfileDetailScreen(contactId: widget.contactId),
                        ),
                      );
                    },
                    child: const CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.contactName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _contactStatus,
                          style: TextStyle(
                            fontSize: 12,
                            color: _contactStatus == 'Online'
                                ? Colors.green
                                : Colors.grey,
                          ),
                        ),
                      ],
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
            onPressed: () => setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) _searchQuery = '';
            }),
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
      body: Stack(
        children: [
          Container(
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
                        return const Center(
                          child: Text('Error loading messages'),
                        );
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
                          String displayText = '';

                          switch (m['type']) {
                            case 'audio':
                              content = Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.play_arrow),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${m['duration'].toStringAsFixed(1)} sec',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    timeStr,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ],
                              );
                              displayText = '[Voice Message]';
                              break;
                            case 'image':
                              content = Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.image),
                                      const SizedBox(width: 8),
                                      const Text('Image'),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    timeStr,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ],
                              );
                              displayText = '[Image]';
                              break;
                            case 'video':
                              content = Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.videocam),
                                      const SizedBox(width: 8),
                                      const Text('Video'),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    timeStr,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ],
                              );
                              displayText = '[Video]';
                              break;
                            case 'file':
                              content = Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.insert_drive_file),
                                      const SizedBox(width: 8),
                                      const Text('File'),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    timeStr,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ],
                              );
                              displayText = '[File]';
                              break;
                            default:
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
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ],
                              );
                              displayText = m['text'] ?? '';
                              break;
                          }

                          return GestureDetector(
                            onLongPress: () {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Pin Message?'),
                                  content: Text(displayText),
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
                                  color: isMe
                                      ? Colors.blue[200]
                                      : Colors.grey[300],
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _showAttachmentOptions
                              ? Icons.close
                              : Icons.attach_file,
                          color: _showAttachmentOptions ? Colors.red : null,
                        ),
                        onPressed: _toggleAttachmentOptions,
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
          // Floating attachment options
          if (_showAttachmentOptions)
            Positioned(
              bottom: 80,
              left: 16,
              child: ScaleTransition(
                scale: _attachmentAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _AttachmentOption(
                      icon: Icons.image,
                      label: 'Image',
                      color: Colors.purple,
                      onTap: _pickImage,
                    ),
                    const SizedBox(height: 8),
                    _AttachmentOption(
                      icon: Icons.videocam,
                      label: 'Video',
                      color: Colors.red,
                      onTap: _pickVideo,
                    ),
                    const SizedBox(height: 8),
                    _AttachmentOption(
                      icon: Icons.insert_drive_file,
                      label: 'File',
                      color: Colors.blue,
                      onTap: _pickFile,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AttachmentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AttachmentOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

// Extension to capitalize strings
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
