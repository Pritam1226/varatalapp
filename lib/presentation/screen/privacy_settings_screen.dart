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
  DisappearingMessageDuration disappearingMessageDuration = DisappearingMessageDuration.off;

  final String uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    loadUserSettings();
  }

  Future<void> loadUserSettings() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) {
      setState(() {
        lastSeenVisibility = doc['lastSeenVisibility'] ?? 'everyone';
        profileVisibility = doc['profileVisibility'] ?? 'everyone';
        final durationStr = doc['disappearingMessageDuration'] ?? 'off';
        disappearingMessageDuration = DisappearingMessageDuration.values.firstWhere(
          (e) => e.toString().split('.').last == durationStr,
          orElse: () => DisappearingMessageDuration.off,
        );
      });
    }
  }

  Future<void> updateVisibility(String field, String value) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      field: value,
    });
    setState(() {
      if (field == 'lastSeenVisibility') lastSeenVisibility = value;
      if (field == 'profileVisibility') profileVisibility = value;
    });
  }

  Future<void> updateDisappearingMessageDuration(DisappearingMessageDuration value) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'disappearingMessageDuration': value.toString().split('.').last,
    });
    setState(() {
      disappearingMessageDuration = value;
    });
  }

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

  String _getDurationText(DisappearingMessageDuration duration) {
    switch (duration) {
      case DisappearingMessageDuration.off:
        return "Off";
      case DisappearingMessageDuration.hours9:
        return "9 Hours";
      case DisappearingMessageDuration.hours24:
        return "24 Hours";
      case DisappearingMessageDuration.days7:
        return "7 Days";
    }
  }

  Widget _buildDisappearingOptions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: DisappearingMessageDuration.values.map((option) {
        return RadioListTile<DisappearingMessageDuration>(
          title: Text(_getDurationText(option)),
          value: option,
          groupValue: disappearingMessageDuration,
          onChanged: (value) {
            if (value != null) {
              updateDisappearingMessageDuration(value);
              Navigator.pop(context);
            }
          },
        );
      }).toList(),
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

            ListTile(
              title: const Text("Disappearing Messages"),
              subtitle: Text(_getDurationText(disappearingMessageDuration)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => _buildDisappearingOptions(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

enum DisappearingMessageDuration {
  off,
  hours9,
  hours24,
  days7,
}
