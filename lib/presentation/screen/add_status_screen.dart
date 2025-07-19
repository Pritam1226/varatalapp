import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

class AddStatusScreen extends StatefulWidget {
  const AddStatusScreen({super.key});

  @override
  State<AddStatusScreen> createState() => _AddStatusScreenState();
}

class _AddStatusScreenState extends State<AddStatusScreen> {
  final picker = ImagePicker();
  final currentUser = FirebaseAuth.instance.currentUser!;
  final TextEditingController _textController = TextEditingController();
  VideoPlayerController? _videoController;
  File? _selectedFile;
  String? _fileType; // image, video, or text
  bool _isUploading = false;

  Future<void> pickMedia(ImageSource source, {required bool isVideo}) async {
    final picked = await (isVideo
        ? picker.pickVideo(source: source)
        : picker.pickImage(source: source));

    if (picked != null) {
      setState(() {
        _selectedFile = File(picked.path);
        _fileType = isVideo ? "video" : "image";

        if (isVideo) {
          _videoController = VideoPlayerController.file(_selectedFile!)
            ..initialize().then((_) {
              setState(() {});
              _videoController!.play();
            });
        }
      });
    }
  }

  Future<void> uploadStatus() async {
    if ((_selectedFile == null && _textController.text.isEmpty) || _isUploading) return;

    setState(() => _isUploading = true);

    String? downloadUrl;

    if (_selectedFile != null) {
      final ref = FirebaseStorage.instance
          .ref('statuses/${currentUser.uid}/${DateTime.now().millisecondsSinceEpoch}');
      await ref.putFile(_selectedFile!);
      downloadUrl = await ref.getDownloadURL();
    }

    await FirebaseFirestore.instance
        .collection('statuses')
        .doc(currentUser.uid)
        .set({
      'uid': currentUser.uid,
      'name': currentUser.displayName ?? 'Unknown',
      'profilePic': currentUser.photoURL ?? '',
      'timestamp': FieldValue.serverTimestamp(),
      'statusList': FieldValue.arrayUnion([
        {
          'type': _fileType ?? 'text',
          'url': downloadUrl ?? '',
          'text': _fileType == 'text' ? _textController.text.trim() : '',
          'time': FieldValue.serverTimestamp(),
        }
      ])
    }, SetOptions(merge: true));

    setState(() {
      _isUploading = false;
      _selectedFile = null;
      _fileType = null;
      _textController.clear();
      _videoController?.dispose();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Status uploaded")),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Status"),
        actions: [
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: uploadStatus,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_fileType == 'image' && _selectedFile != null)
              Image.file(_selectedFile!),
            if (_fileType == 'video' &&
                _selectedFile != null &&
                _videoController != null &&
                _videoController!.value.isInitialized)
              AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              ),
            if (_fileType == null || _fileType == 'text')
              TextField(
                controller: _textController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: "Type your status text...",
                  border: OutlineInputBorder(),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: () => pickMedia(ImageSource.gallery, isVideo: false),
                ),
                IconButton(
                  icon: const Icon(Icons.videocam),
                  onPressed: () => pickMedia(ImageSource.gallery, isVideo: true),
                ),
                IconButton(
                  icon: const Icon(Icons.camera_alt),
                  onPressed: () => pickMedia(ImageSource.camera, isVideo: false),
                ),
              ],
            ),
            if (_isUploading) const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
