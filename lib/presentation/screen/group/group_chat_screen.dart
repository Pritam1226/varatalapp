import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:varatalapp/presentation/screen/group/group_info_screen.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;

  const GroupChatScreen({super.key, required this.groupId});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  List<String> _participants = [];
  bool _showAttachmentOptions = false;
  bool _isUploading = false;
  bool _isSearching = false;
  String _searchQuery = '';
  Map<String, dynamic>? _groupData;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fetchParticipants();
    _fetchGroupData();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(
          begin: const Offset(0, 0.5),
          end: const Offset(0, 0),
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.elasticOut,
          ),
        );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
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

  Future<void> _fetchGroupData() async {
    final groupSnapshot = await _firestore
        .collection('groups')
        .doc(widget.groupId)
        .get();
    setState(() {
      _groupData = groupSnapshot.data();
    });
  }

  // Search functionality
  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchQuery = '';
        _searchController.clear();
      }
    });
  }

  void _updateSearchQuery(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  bool _messageMatchesSearch(Map<String, dynamic> data) {
    if (_searchQuery.isEmpty) return true;
    final text = (data['text'] ?? '').toString().toLowerCase();
    final senderName = (data['senderName'] ?? '').toString().toLowerCase();
    return text.contains(_searchQuery) || senderName.contains(_searchQuery);
  }

  // Wallpaper functionality
  Future<void> _changeWallpaper() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        final file = File(image.path);
        final currentUser = _auth.currentUser;
        if (currentUser == null) return;

        setState(() {
          _isUploading = true;
        });

        final fileName = path.basename(file.path);
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final storageRef = _storage.ref().child(
          'group_wallpapers/${widget.groupId}/${currentUser.uid}_${timestamp}_$fileName',
        );

        final uploadTask = storageRef.putFile(file);
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();

        // Save wallpaper URL to group document
        await _firestore.collection('groups').doc(widget.groupId).update({
          'wallpaper': downloadUrl,
        });

        setState(() {
          _isUploading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Wallpaper updated successfully!")),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to update wallpaper: $e")));
    }
  }

  // Navigation Drawer
  Widget _buildNavigationDrawer() {
    return Drawer(
      child: Column(
        children: [
          // Header
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color.fromARGB(255, 93, 153, 232),
                  const Color.fromARGB(255, 46, 109, 218),
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundImage:
                          _groupData?['groupIcon'] != null &&
                              _groupData!['groupIcon'].toString().isNotEmpty
                          ? NetworkImage(_groupData!['groupIcon'])
                          : null,
                      child:
                          _groupData?['groupIcon'] == null ||
                              _groupData!['groupIcon'].toString().isEmpty
                          ? const Icon(
                              Icons.group,
                              size: 35,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _groupData?['groupName'] ?? 'Group Chat',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_participants.length} participants',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.search,
                  title: 'Search Messages',
                  onTap: () {
                    Navigator.pop(context);
                    _toggleSearch();
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.info_outline,
                  title: 'Group Info',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            GroupInfoScreen(groupId: widget.groupId),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.wallpaper,
                  title: 'Change Wallpaper',
                  onTap: () {
                    Navigator.pop(context);
                    _changeWallpaper();
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.notifications_outlined,
                  title: 'Mute Notifications',
                  onTap: () {
                    Navigator.pop(context);
                    _showMuteDialog();
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.photo_library,
                  title: 'Media & Files',
                  onTap: () {
                    Navigator.pop(context);
                    _showMediaDialog();
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.star_outline,
                  title: 'Starred Messages',
                  onTap: () {
                    Navigator.pop(context);
                    _showStarredMessages();
                  },
                ),
                const Divider(),
                _buildDrawerItem(
                  icon: Icons.delete_outline,
                  title: 'Clear Chat',
                  onTap: () {
                    Navigator.pop(context);
                    _showClearChatDialog();
                  },
                  isDestructive: true,
                ),
                _buildDrawerItem(
                  icon: Icons.exit_to_app,
                  title: 'Exit Group',
                  onTap: () {
                    Navigator.pop(context);
                    _showExitGroupDialog();
                  },
                  isDestructive: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : Colors.grey[700]),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      dense: true,
    );
  }

  // Dialog functions
  void _showMuteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mute Notifications'),
        content: const Text('Choose duration to mute notifications:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement mute for 8 hours
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notifications muted for 8 hours'),
                ),
              );
            },
            child: const Text('8 Hours'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement mute for 1 week
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications muted for 1 week')),
              );
            },
            child: const Text('1 Week'),
          ),
        ],
      ),
    );
  }

  void _showMediaDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Media & Files'),
        content: const Text('Feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showStarredMessages() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Starred Messages'),
        content: const Text('Feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text(
          'Are you sure you want to clear all messages in this group?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement clear chat functionality
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Chat cleared')));
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showExitGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Group'),
        content: const Text('Are you sure you want to exit this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to previous screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('You have left the group')),
              );
            },
            child: const Text('Exit', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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
      'type': 'text',
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

  Future<void> _sendMediaMessage({
    required String downloadUrl,
    required String fileName,
    required String messageType,
    String? thumbnailUrl,
  }) async {
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
      'text': fileName,
      'fileUrl': downloadUrl,
      'fileName': fileName,
      'type': messageType,
      'timestamp': FieldValue.serverTimestamp(),
      'readBy': readStatus,
      if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
    };

    try {
      await _firestore
          .collection('groups')
          .doc(widget.groupId)
          .collection('messages')
          .add(messageData);
      await _firestore.collection('groups').doc(widget.groupId).update({
        'lastMessage': messageType == 'image' ? '📷 Image' : '📎 File',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to send $messageType. Please try again."),
        ),
      );
    }
  }

  Future<String?> _uploadFile(File file, String messageType) async {
    try {
      setState(() {
        _isUploading = true;
      });

      final currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      final fileName = path.basename(file.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storageRef = _storage.ref().child(
        'group_messages/${widget.groupId}/$messageType/${currentUser.uid}_${timestamp}_$fileName',
      );

      final uploadTask = storageRef.putFile(file);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to upload file: $e")));
      return null;
    } finally {
      setState(() {
        _isUploading = false;
      });
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

  void _toggleAttachmentOptions() {
    if (_showAttachmentOptions) {
      _animationController.reverse().then((_) {
        setState(() {
          _showAttachmentOptions = false;
        });
      });
    } else {
      setState(() {
        _showAttachmentOptions = true;
      });
      _animationController.forward();
    }
  }

  Future<void> _handleImagePicker() async {
    _toggleAttachmentOptions();

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        final file = File(image.path);
        final downloadUrl = await _uploadFile(file, 'image');

        if (downloadUrl != null) {
          await _sendMediaMessage(
            downloadUrl: downloadUrl,
            fileName: path.basename(image.path),
            messageType: 'image',
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to pick image: $e")));
    }
  }

  Future<void> _handleVideoPicker() async {
    _toggleAttachmentOptions();

    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );

      if (video != null) {
        final file = File(video.path);
        final downloadUrl = await _uploadFile(file, 'video');

        if (downloadUrl != null) {
          await _sendMediaMessage(
            downloadUrl: downloadUrl,
            fileName: path.basename(video.path),
            messageType: 'video',
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to pick video: $e")));
    }
  }

  Future<void> _handleFilePicker() async {
    _toggleAttachmentOptions();

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;

        // Check file size (limit to 10MB)
        final fileSizeInBytes = await file.length();
        final fileSizeInMB = fileSizeInBytes / (1024 * 1024);

        if (fileSizeInMB > 10) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("File size should not exceed 10MB")),
          );
          return;
        }

        final downloadUrl = await _uploadFile(file, 'file');

        if (downloadUrl != null) {
          await _sendMediaMessage(
            downloadUrl: downloadUrl,
            fileName: fileName,
            messageType: 'file',
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to pick file: $e")));
    }
  }

  Future<void> _handleCameraPicker() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        final file = File(image.path);
        final downloadUrl = await _uploadFile(file, 'image');

        if (downloadUrl != null) {
          await _sendMediaMessage(
            downloadUrl: downloadUrl,
            fileName: path.basename(image.path),
            messageType: 'image',
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to take photo: $e")));
    }
  }

  Widget _buildMessageContent(Map<String, dynamic> data, bool isMe) {
    final messageType = data['type'] ?? 'text';

    switch (messageType) {
      case 'image':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data['fileUrl'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  data['fileUrl'],
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 200,
                      height: 200,
                      alignment: Alignment.center,
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                ),
              ),
            if (data['fileName'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  data['fileName'],
                  style: TextStyle(
                    fontSize: 12,
                    color: isMe ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
          ],
        );
      case 'video':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 200,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.play_circle_fill,
                size: 50,
                color: Colors.white,
              ),
            ),
            if (data['fileName'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  data['fileName'],
                  style: TextStyle(
                    fontSize: 12,
                    color: isMe ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
          ],
        );
      case 'file':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insert_drive_file,
              color: isMe ? Colors.white : Colors.black54,
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                data['fileName'] ?? 'File',
                style: TextStyle(
                  fontSize: 15,
                  color: isMe ? Colors.white : Colors.black,
                ),
              ),
            ),
          ],
        );
      default:
        return Text(
          data['text'] ?? '',
          style: TextStyle(
            fontSize: 15,
            color: isMe ? Colors.white : Colors.black,
          ),
        );
    }
  }

  Widget _buildAttachmentOptions() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              margin: const EdgeInsets.only(bottom: 10, left: 10, right: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttachmentButton(
                    icon: Icons.photo,
                    label: "Image",
                    color: Colors.green,
                    onTap: _handleImagePicker,
                  ),
                  _buildAttachmentButton(
                    icon: Icons.videocam,
                    label: "Video",
                    color: Colors.red,
                    onTap: _handleVideoPicker,
                  ),
                  _buildAttachmentButton(
                    icon: Icons.insert_drive_file,
                    label: "File",
                    color: Colors.blue,
                    onTap: _handleFilePicker,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttachmentButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _isUploading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(_isUploading ? 0.1 : 0.2),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: color.withOpacity(_isUploading ? 0.3 : 0.5),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: _isUploading ? color.withOpacity(0.5) : color,
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: _isUploading ? color.withOpacity(0.5) : color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
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
      drawer: _buildNavigationDrawer(), // Added navigation drawer
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 93, 153, 232),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu), // Three-line menu icon
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: "Search messages...",
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: _updateSearchQuery,
                autofocus: true,
              )
            : StreamBuilder<DocumentSnapshot>(
                stream: _firestore
                    .collection('groups')
                    .doc(widget.groupId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Text("Group Chat");
                  }
                  final groupData =
                      snapshot.data!.data() as Map<String, dynamic>;
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
                          child: groupImage.isEmpty
                              ? const Icon(Icons.group)
                              : null,
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
        actions: [
          if (_isSearching)
            IconButton(icon: const Icon(Icons.close), onPressed: _toggleSearch)
          else
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _toggleSearch,
            ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Show additional options menu
              showModalBottomSheet(
                context: context,
                builder: (context) => Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.info_outline),
                        title: const Text('Group Info'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  GroupInfoScreen(groupId: widget.groupId),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.wallpaper),
                        title: const Text('Change Wallpaper'),
                        onTap: () {
                          Navigator.pop(context);
                          _changeWallpaper();
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.delete_outline),
                        title: const Text('Clear Chat'),
                        onTap: () {
                          Navigator.pop(context);
                          _showClearChatDialog();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          if (_showAttachmentOptions) {
            _toggleAttachmentOptions();
          }
        },
        child: Container(
          decoration: _groupData != null && _groupData!['wallpaper'] != null
              ? BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(_groupData!['wallpaper']),
                    fit: BoxFit.cover,
                  ),
                )
              : null,
          child: Column(
            children: [
              if (_isUploading)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  color: Colors.blue[100],
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text("Uploading...", style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              if (_isSearching && _searchQuery.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  color: Colors.amber[100],
                  child: Text(
                    "Searching for: $_searchQuery",
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
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

                    final allMessages = snapshot.data!.docs;
                    final messages = _isSearching
                        ? allMessages
                              .where(
                                (msg) => _messageMatchesSearch(
                                  msg.data() as Map<String, dynamic>,
                                ),
                              )
                              .toList()
                        : allMessages;

                    if (_isSearching && messages.isEmpty) {
                      return const Center(child: Text("No messages found"));
                    }

                    return ListView.builder(
                      reverse:
                          !_isSearching, // Don't reverse for search results
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final data = msg.data() as Map<String, dynamic>;
                        final isMe = data['senderId'] == currentUser.uid;
                        final readBy = Map<String, dynamic>.from(
                          data['readBy'] ?? {},
                        );

                        if (!isMe) _markAsRead(msg);

                        return Container(
                          color: _isSearching && _searchQuery.isNotEmpty
                              ? Colors.yellow.withOpacity(0.1)
                              : Colors.transparent,
                          child: Padding(
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
                                      MediaQuery.of(context).size.width * 0.7,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? const Color.fromARGB(
                                            255,
                                            87,
                                            151,
                                            234,
                                          )
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (!isMe)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 4,
                                          ),
                                          child: Text(
                                            data['senderName'] ?? '',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      _buildMessageContent(data, isMe),
                                      if (isMe)
                                        Align(
                                          alignment: Alignment.bottomRight,
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4,
                                            ),
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
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              if (_showAttachmentOptions) _buildAttachmentOptions(),
              const Divider(height: 1),
              Container(
                color: _groupData != null && _groupData!['wallpaper'] != null
                    ? Colors.white.withOpacity(0.9)
                    : Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _showAttachmentOptions
                              ? Icons.close
                              : Icons.attach_file,
                        ),
                        onPressed: _isUploading
                            ? null
                            : _toggleAttachmentOptions,
                        color: _showAttachmentOptions
                            ? Colors.red
                            : Colors.grey[600],
                      ),
                      IconButton(
                        icon: const Icon(Icons.camera_alt),
                        onPressed: _isUploading ? null : _handleCameraPicker,
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
                          enabled: !_isUploading,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _isUploading ? null : _sendMessage,
                        color: const Color.fromARGB(255, 46, 109, 218),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
