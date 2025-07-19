import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:story_view/story_view.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:video_player/video_player.dart';

class StatusViewerScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String userImage;

  const StatusViewerScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.userImage, required List<QueryDocumentSnapshot<Object?>> statuses, required bool isMyStatus,
  });

  @override
  State<StatusViewerScreen> createState() => _StatusViewerScreenState();
}

class _StatusViewerScreenState extends State<StatusViewerScreen> {
  final StoryController _storyController = StoryController();
  List<StoryItem> storyItems = [];
  bool isLoading = true;

  final currentUser = FirebaseAuth.instance.currentUser!;

  @override
  void initState() {
    super.initState();
    _loadStatuses();
  }

  Future<void> _loadStatuses() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('statuses')
          .doc(widget.userId)
          .collection('updates')
          .orderBy('timestamp')
          .get();

      final now = DateTime.now();

      storyItems = snapshot.docs.map((doc) {
        final data = doc.data();
        final mediaUrl = data['mediaUrl'];
        final mediaType = data['mediaType'];
        final text = data['text'];
        final postedTime = (data['timestamp'] as Timestamp).toDate();
        final docId = doc.id;

        // Skip expired statuses
        if (now.difference(postedTime).inHours >= 24) {
          // Auto-delete expired
          FirebaseFirestore.instance
              .collection('statuses')
              .doc(widget.userId)
              .collection('updates')
              .doc(docId)
              .delete();
          return null;
        }

        if (mediaType == 'image') {
          return StoryItem.pageImage(
            url: mediaUrl,
            controller: _storyController,
            caption: text,
          );
        } else if (mediaType == 'video') {
          return StoryItem.pageVideo(
            mediaUrl,
            controller: _storyController,
            caption: text,
          );
        } else {
          return StoryItem.text(
            title: text ?? '',
            backgroundColor: Colors.deepPurple,
          );
        }
      }).whereType<StoryItem>().toList();

      if (mounted) {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error loading statuses: $e");
      setState(() => isLoading = false);
    }
  }

  void _deleteStatus() async {
    final statusRef = FirebaseFirestore.instance
        .collection('statuses')
        .doc(widget.userId)
        .collection('updates');

    final snapshot = await statusRef.get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _storyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (storyItems.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: Text("No status found", style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          StoryView(
            storyItems: storyItems,
            controller: _storyController,
            onComplete: () {
              Navigator.pop(context);
            },
            onVerticalSwipeComplete: (direction) {
              if (direction == Direction.down) Navigator.pop(context);
            },
          ),
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(widget.userImage),
                  radius: 24,
                ),
                const SizedBox(width: 10),
                Text(
                  widget.userName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                if (widget.userId == currentUser.uid)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.white),
                    onPressed: _deleteStatus,
                  ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
