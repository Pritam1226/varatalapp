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
      });
    }
  }

  // Update selected visibility option in Firestore
  Future<void> updateVisibility(String field, String value) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      field: value,
    });
    setState(() {
      if (field == 'lastSeenVisibility') lastSeenVisibility = value;
      if (field == 'profileVisibility') profileVisibility = value;
    });
  }

  // Build Dropdown for each setting
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildDropdown('Last Seen & Online', lastSeenVisibility, 'lastSeenVisibility'),
            buildDropdown('Profile Photo Visibility', profileVisibility, 'profileVisibility'),
          ],
        ),
      ),
    );
  }
}
