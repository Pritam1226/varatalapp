import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> allUsers = [];
  List<String> selectedUserIds = [];
  File? _selectedImage;
  bool isLoading = false;
  bool isUserLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final usersSnapshot = await _firestore.collection('users').get();

      final users = usersSnapshot.docs
          .where((doc) => doc.id != currentUser.uid)
          .map(
            (doc) => {
              'uid': doc.id,
              'name': doc.data()['name'] ?? 'No Name',
              'email': doc.data()['email'] ?? '',
              'profileImage': doc.data()['profileImage'] ?? '',
            },
          )
          .toList();

      setState(() {
        allUsers = users;
        isUserLoading = false;
      });
    } catch (e) {
      setState(() {
        isUserLoading = false;
      });
      print('Error loading users: $e');
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _selectedImage = File(pickedImage.path);
      });
    }
  }

  Future<String?> uploadGroupImage(String groupId) async {
    if (_selectedImage == null) return null;

    final ref = FirebaseStorage.instance
        .ref()
        .child('group_images')
        .child('$groupId.jpg');

    await ref.putFile(_selectedImage!);
    return await ref.getDownloadURL();
  }

  Future<void> createGroup() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || _groupNameController.text.trim().isEmpty) return;

    setState(() {
      isLoading = true;
    });

    // Generate a group document reference and ID
    final groupDocRef = _firestore.collection('groups').doc();
    final groupId = groupDocRef.id;

    final imageUrl = await uploadGroupImage(groupId);
    final members = [...selectedUserIds, currentUser.uid];

    await groupDocRef.set({
      'groupId': groupId, // ✅ Add groupId field
      'groupName': _groupNameController.text.trim(),
      'groupImageUrl': imageUrl ?? '',
      'members': members,
      'admins': [currentUser.uid], // ✅ Add current user as admin
      'createdBy': currentUser.uid,
      'createdAt': Timestamp.now(),
      'lastMessage': '',
      'lastMessageTime': Timestamp.now(),
      'unreadCounts': {for (var uid in members) uid: 0},
    });

    setState(() {
      isLoading = false;
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Group')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: pickImage,
                    child: CircleAvatar(
                      radius: 40,
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!)
                          : null,
                      child: _selectedImage == null
                          ? const Icon(Icons.camera_alt, size: 30)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _groupNameController,
                    decoration: const InputDecoration(
                      labelText: 'Group Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Select Participants',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (isUserLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (allUsers.isEmpty)
                    const Center(child: Text('No users found'))
                  else
                    ...allUsers.map((user) {
                      final uid = user['uid'];
                      final isSelected = selectedUserIds.contains(uid);
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: user['profileImage'] != ''
                              ? NetworkImage(user['profileImage'])
                              : null,
                          child: user['profileImage'] == ''
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text(user['name']),
                        subtitle: Text(user['email']),
                        trailing: Checkbox(
                          value: isSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                selectedUserIds.add(uid);
                              } else {
                                selectedUserIds.remove(uid);
                              }
                            });
                          },
                        ),
                      );
                    }),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: createGroup,
                      child: const Text('Create Group'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
