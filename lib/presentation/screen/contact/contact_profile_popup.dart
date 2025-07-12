import 'package:flutter/material.dart';
import 'package:varatalapp/presentation/screen/chatscreen.dart';
import 'package:varatalapp/presentation/screen/contact/profile_detail_screen.dart';

class ContactProfilePopup extends StatelessWidget {
  final String contactId;
  final String contactName;
  final String? profileImageUrl;

  const ContactProfilePopup({
    super.key,
    required this.contactId,
    required this.contactName,
    this.profileImageUrl,
  });

  String getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return parts[0][0].toUpperCase() + parts[1][0].toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Name
          Container(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              contactName,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 10),

          // Avatar with image or initials
          CircleAvatar(
            radius: 80,
            backgroundColor: Colors.deepPurple,
            backgroundImage: (profileImageUrl != null && profileImageUrl!.isNotEmpty)
                ? NetworkImage(profileImageUrl!)
                : null,
            child: (profileImageUrl == null || profileImageUrl!.isEmpty)
                ? Text(
                    getInitials(contactName),
                    style: const TextStyle(fontSize: 40, color: Colors.pinkAccent),
                  )
                : null,
          ),

          const SizedBox(height: 20),

          // Bottom buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  tooltip: "Message",
                  icon: const Icon(Icons.chat, color: Colors.green),
                  onPressed: () {
                    Navigator.pop(context); // Close popup
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          contactId: contactId,
                          contactName: contactName,
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  tooltip: "Details",
                  icon: const Icon(Icons.info_outline, color: Colors.green),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfileDetailScreen(contactId: contactId),
                      ),
                    );
                  },
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
