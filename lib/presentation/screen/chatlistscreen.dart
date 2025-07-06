import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:intl/intl.dart';
import 'chatscreen.dart'; // ✅ Make sure this file exists in the same folder or update the path

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
  Set<int> pinnedChats = {};
  String searchQuery = '';

  void _addDummyContact() {
    final now = DateTime.now();
    setState(() {
      chatList.add(
        Chat(
          contactName: "Contact ${chatList.length + 1}",
          lastMessage: "Hay! This is message ${chatList.length + 1}",
          lastMessageTime: now,
        ),
      );
    });
  }

  List<Chat> get sortedChats {
    final pinned = <Chat>[];
    final normal = <Chat>[];

    for (int i = 0; i < chatList.length; i++) {
      if (pinnedChats.contains(i)) {
        pinned.add(chatList[i]);
      } else {
        normal.add(chatList[i]);
      }
    }

    return [...pinned, ...normal];
  }

  List<Chat> get filteredChats {
    return sortedChats.where((chat) {
      final name = chat.contactName.toLowerCase();
      final msg = chat.lastMessage.toLowerCase();
      return name.contains(searchQuery) || msg.contains(searchQuery);
    }).toList();
  }

  String formatTime(DateTime time) {
    return DateFormat('hh:mm a').format(time);
  }

  void _togglePin(int index) {
    setState(() {
      if (pinnedChats.contains(index)) {
        pinnedChats.remove(index);
      } else {
        pinnedChats.add(index);
      }
    });
  }

  void _deleteChat(int index) {
    setState(() {
      chatList.removeAt(index);
      pinnedChats.remove(index);
    });
  }

  void _archiveChat(int index) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Chat archived (not implemented)")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chats"),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              // TODO: Handle menu options
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(value: 'new_group', child: Text('New Group')),
              const PopupMenuItem(value: 'settings', child: Text('Settings')),
              const PopupMenuItem(value: 'logout', child: Text('Logout')),
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
                    itemBuilder: (context, filteredIndex) {
                      final Chat chat = filteredChats[filteredIndex];
                      final actualIndex =
                          chatList.indexWhere((c) => c == chat);

                      return Dismissible(
                        key: Key(chat.contactName + actualIndex.toString()),
                        background: Container(
                          color: Colors.green,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 20),
                          child: const Icon(Icons.archive, color: Colors.white),
                        ),
                        secondaryBackground: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.startToEnd) {
                            _archiveChat(actualIndex);
                            return false; // Prevent actual dismiss for archive
                          } else if (direction == DismissDirection.endToStart) {
                            return true; // Allow delete
                          }
                          return false;
                        },
                        onDismissed: (direction) {
                          _deleteChat(actualIndex);
                        },
                        child: ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.person)),
                          title: Row(
                            children: [
                              Text(chat.contactName),
                              if (pinnedChats.contains(actualIndex))
                                const Padding(
                                  padding: EdgeInsets.only(left: 6.0),
                                  child: Icon(Icons.push_pin, size: 16),
                                ),
                            ],
                          ),
                          subtitle: Text(chat.lastMessage),
                          trailing: Text(formatTime(chat.lastMessageTime)),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  contactName: chat.contactName,
                                  contactId: chat.contactName,
                                ),
                              ),
                            );
                          },
                          onLongPress: () => _togglePin(actualIndex),
                        ),
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
