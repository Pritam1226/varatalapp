import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:intl/intl.dart';

class Chat {
  final String contactName;
  final String lastMessage;
  final DateTime lastMessageTime;

  Chat({
    required this.contactName,
    required this.lastMessage,
    required this.lastMessageTime,
  });
}

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<Chat> chatList = [];
  String searchQuery = '';

  void _addDummyContact() {
    final now = DateTime.now();
    setState(() {
      chatList.add(
        Chat(
          contactName: "Contact ${chatList.length + 1}",
          lastMessage: "Hello! This is message ${chatList.length + 1}",
          lastMessageTime: now,
        ),
      );
    });
  }

  List<Chat> get filteredChats {
    return chatList.where((chat) {
      final name = chat.contactName.toLowerCase();
      final msg = chat.lastMessage.toLowerCase();
      return name.contains(searchQuery) || msg.contains(searchQuery);
    }).toList();
  }

  String formatTime(DateTime time) {
    return DateFormat('hh:mm a').format(time);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chats"),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'settings') {
                // TODO: Navigate to settings screen
              } else if (value == 'logout') {
                // TODO: Handle logout
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'new_group',
                child: Text('New Group'),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Text('Settings'),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search contact or message',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: filteredChats.isEmpty
                ? const Center(child: Text("No chats found."))
                : ListView.builder(
                    itemCount: filteredChats.length,
                    itemBuilder: (context, index) {
                      final chat = filteredChats[index];
                      return ListTile(
                        leading:
                            const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(chat.contactName),
                        subtitle: Text(chat.lastMessage),
                        trailing: Text(formatTime(chat.lastMessageTime)),
                        onTap: () {
                          // TODO: Navigate to chat screen
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: SpeedDial(
        animatedIcon: AnimatedIcons.menu_close,
        backgroundColor: Theme.of(context).primaryColor,
        tooltip: "Options",
        children: [
          SpeedDialChild(
            child: const Icon(Icons.person_add),
            label: 'Add Contact',
            onTap: _addDummyContact,
          ),
        ],
      ),
    );
  }
}
