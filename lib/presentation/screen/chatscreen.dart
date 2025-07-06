import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  final String contactName;
  final String contactId;

  const ChatScreen({
    Key? key,
    required this.contactName,
    required this.contactId,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _messages.insert(0, {
        'sender': 'me',
        'text': message,
        'timestamp': DateTime.now(),
      });
      _isTyping = false;
    });

    _messageController.clear();

    // Auto-scroll to bottom after a small delay
    Future.delayed(Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        0.0,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.contactName),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (ctx, index) {
                final msg = _messages[index];
                final isMe = msg['sender'] == 'me';
                return Align(
                  alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                        vertical: 4.0, horizontal: 10.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blue[200] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          msg['text'],
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 4),
                        Text(
                          msg['timestamp'].toString().substring(11, 16),
                          style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          if (_isTyping)
            Padding(
              padding: const EdgeInsets.only(left: 16.0, bottom: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "typing...",
                  style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                ),
              ),
            ),

          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.attach_file),
                  onPressed: () {
                    // TODO: Add file/image picker
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Type your message...",
                      border: InputBorder.none,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _isTyping = value.isNotEmpty;
                      });
                    },
                  ),
                ),
                IconButton(
                  onPressed: _sendMessage,
                  icon: Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
