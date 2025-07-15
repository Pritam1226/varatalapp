import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  Map<String, dynamic>? userData;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (snapshot.exists) {
      setState(() {
        userData = snapshot.data();
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (userData == null) {
      return const Scaffold(body: Center(child: Text('User data not found.')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _showEditForm,
              child: CircleAvatar(
                radius: 50,
                backgroundImage:
                    (userData!['profileImageUrl'] ?? '').toString().isNotEmpty
                    ? NetworkImage(userData!['profileImageUrl'])
                    : null,
                child: (userData!['profileImageUrl'] ?? '').toString().isEmpty
                    ? const Icon(Icons.person, size: 50)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              userData!['name'] ?? 'No Name',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              userData!['bio'] ?? 'No Bio',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.email),
              title: Text(userData!['email'] ?? ''),
            ),
            ListTile(
              leading: const Icon(Icons.phone),
              title: Text(userData!['phone'] ?? ''),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _showEditForm,
              icon: const Icon(Icons.edit, color: Colors.white),
              label: const Text(
                "Edit Profile",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 4, 97, 197),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                shadowColor: Colors.tealAccent.withOpacity(0.4),
                splashFactory: InkRipple.splashFactory,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditForm() {
    final nameController = TextEditingController(text: userData!['name']);
    final bioController = TextEditingController(text: userData!['bio']);
    File? selectedImage;
    bool uploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Edit Profile',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final picked = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                  );
                  if (picked != null) {
                    setModalState(() => selectedImage = File(picked.path));
                  }
                },
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: selectedImage != null
                      ? FileImage(selectedImage!)
                      : (userData!['profileImageUrl'] ?? '')
                            .toString()
                            .isNotEmpty
                      ? NetworkImage(userData!['profileImageUrl'])
                      : null,
                  child:
                      (selectedImage == null &&
                          (userData!['profileImageUrl'] ?? '')
                              .toString()
                              .isEmpty)
                      ? const Icon(Icons.camera_alt, size: 30)
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: bioController,
                decoration: const InputDecoration(labelText: 'Bio'),
              ),
              const SizedBox(height: 20),
              uploading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      child: const Text('Save'),
                      onPressed: () async {
                        setModalState(() => uploading = true);

                        String imageUrl = userData!['profileImageUrl'] ?? '';
                        if (selectedImage != null) {
                          final ref = FirebaseStorage.instance.ref(
                            'profile_images/$uid.jpg',
                          );
                          await ref.putFile(selectedImage!);
                          imageUrl = await ref.getDownloadURL();
                        }

                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .update({
                              'name': nameController.text.trim(),
                              'bio': bioController.text.trim(),
                              'profileImageUrl': imageUrl,
                            });

                        await _fetchUserData(); // Refresh
                        if (mounted) Navigator.pop(context);
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
