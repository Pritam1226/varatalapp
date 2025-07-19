import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:varatalapp/presentation/screen/add_status_screen.dart';
import 'package:varatalapp/presentation/screen/status_viewer_screen.dart';

class UpdatesScreen extends StatelessWidget {
  const UpdatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Updates"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddStatusScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('status')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No status updates found'));
          }

          final allStatuses = snapshot.data!.docs;

          final myStatuses = allStatuses
              .where((doc) => doc['userId'] == currentUser!.uid)
              .toList();

          final otherStatuses = allStatuses
              .where((doc) => doc['userId'] != currentUser!.uid)
              .toList();

          // Group statuses by userId
          final Map<String, List<QueryDocumentSnapshot>> groupedStatuses = {};
          for (var doc in otherStatuses) {
            final userId = doc['userId'];
            if (!groupedStatuses.containsKey(userId)) {
              groupedStatuses[userId] = [];
            }
            groupedStatuses[userId]!.add(doc);
          }

          return ListView(
            children: [
              if (myStatuses.isNotEmpty)
                ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(
                      myStatuses.first['userImage'],
                    ),
                  ),
                  title: const Text('My Status'),
                  subtitle: Text(
                    '${myStatuses.length} update${myStatuses.length > 1 ? 's' : ''}',
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StatusViewerScreen(
                        userId: currentUser!.uid,
                        userName: myStatuses.first['userName'],
                        userImage: myStatuses.first['userImage'],
                        statuses: myStatuses,
                        isMyStatus: true,
                      ),
                    ),
                  ),
                )
              else
                ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.add)),
                  title: const Text('My Status'),
                  subtitle: const Text('Tap to add status update'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddStatusScreen(),
                      ),
                    );
                  },
                ),
              const Divider(),
              if (groupedStatuses.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Recent updates',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ...groupedStatuses.entries.map((entry) {
                final userStatuses = entry.value;
                final userData = userStatuses.first;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(userData['userImage']),
                  ),
                  title: Text(userData['userName']),
                  subtitle: Text(
                    '${userStatuses.length} update${userStatuses.length > 1 ? 's' : ''}',
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StatusViewerScreen(
                          userId: userData['userId'],
                          userName: userData['userName'],
                          userImage: userData['userImage'],
                          statuses: userStatuses,
                          isMyStatus: false,
                        ),
                      ),
                    );
                  },
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
