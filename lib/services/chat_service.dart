import 'package:cloud_firestore/cloud_firestore.dart';

/// Call this whenever the current user sends a new text message.
///
/// • `chatId`      – Firestore doc ID in `chats/*`  
/// • `message`     – Plain‑text message body  
/// • `currentUserId` – UID of the sender (FirebaseAuth.instance.currentUser!.uid)  
/// • `recipientId` – UID of the person receiving the message
Future<void> sendMessage(
  String chatId,
  String message,
  String currentUserId,
  String recipientId,
) async {
  final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);

  // 1️⃣  Add the message to the sub‑collection
  await chatRef.collection('messages').add({
    'sender': currentUserId,
    'text'  : message.trim(),
    'timestamp': Timestamp.now(),
  });

  // 2️⃣  Update parent chat doc:
  //     • lastMessage / lastMessageTime
  //     • increment recipient’s unread count
  await chatRef.update({
    'lastMessage'        : message.trim(),
    'lastMessageTime'    : Timestamp.now(),
    'unreadCounts.$recipientId': FieldValue.increment(1),
  });
}
