import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  String lastSeenVisibility = 'everyone';
  String profileVisibility = 'everyone';
  bool disappearingMessages = false;

  final String uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    loadUserSettings();
  }

  // Load existing settings from Firestore
  Future<void> loadUserSettings() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) {
      setState(() {
        lastSeenVisibility = doc['lastSeenVisibility'] ?? 'everyone';
        profileVisibility = doc['profileVisibility'] ?? 'everyone';
        disappearingMessages = doc['disappearingMessages'] ?? false;
      });
    }
  }

  // Update dropdown values in Firestore
  Future<void> updateVisibility(String field, String value) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      field: value,
    });
    setState(() {
      if (field == 'lastSeenVisibility') lastSeenVisibility = value;
      if (field == 'profileVisibility') profileVisibility = value;
    });
  }

  // Update switch value in Firestore
  Future<void> updateDisappearingMessages(bool value) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'disappearingMessages': value,
    });
    setState(() {
      disappearingMessages = value;
    });
  }

  // Dropdown builder
  Widget buildDropdown(String label, String value, String fieldKey) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        DropdownButton<String>(
          value: value,
          items: ['everyone', 'my_contacts', 'nobody']
              .map((option) => DropdownMenuItem<String>(
                    value: option,
                    child: Text(option.replaceAll('_', ' ').toUpperCase()),
                  ))
              .toList(),
          onChanged: (selectedValue) {
            if (selectedValue != null) {
              updateVisibility(fieldKey, selectedValue);
            }
          },
        ),
        const Divider(height: 32),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            buildDropdown('Last Seen & Online', lastSeenVisibility, 'lastSeenVisibility'),
            buildDropdown('Profile Photo Visibility', profileVisibility, 'profileVisibility'),

            // 👇 New Switch for Disappearing Messages
            SwitchListTile(
              title: const Text('Disappearing Messages'),
              subtitle: const Text('Messages will disappear after 24 hours'),
              value: disappearingMessages,
              onChanged: (value) => updateDisappearingMessages(value),
            ),
          ],
        ),
      ),
    );
  }
}
