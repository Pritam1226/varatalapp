import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'updates_screen.dart';

class AddStatusScreen extends StatefulWidget {
  const AddStatusScreen({super.key});

  @override
  State<AddStatusScreen> createState() => _AddStatusScreenState();
}

class _AddStatusScreenState extends State<AddStatusScreen> {
  File? _image;
  final picker = ImagePicker();
  bool _isUploading = false;

  Future pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _image = File(picked.path);
      });
    }
  }

  Future uploadStatus() async {
    if (_image == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final name = FirebaseAuth.instance.currentUser?.displayName ?? 'User';
      final photoURL = FirebaseAuth.instance.currentUser?.photoURL ?? '';

      final ref = FirebaseStorage.instance
          .ref()
          .child('status')
          .child('$uid-${DateTime.now().millisecondsSinceEpoch}.jpg');

      await ref.putFile(_image!);
      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('statuses').doc(uid).set({
        'uid': uid,
        'name': name,
        'profilePic': photoURL,
        'statusUrl': url,
        'timestamp': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context);
    } catch (e) {
      debugPrint('Upload failed: $e');
    }

    setState(() {
      _isUploading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Status")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _image != null
                ? Image.file(_image!, height: 200)
                : const Icon(Icons.image, size: 100, color: Colors.grey),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: pickImage,
              child: const Text("Pick Image"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isUploading ? null : uploadStatus,
              child: _isUploading
                  ? const CircularProgressIndicator()
                  : const Text("Upload Status"),
            ),
          ],
        ),
      ),
    );
  }
}
