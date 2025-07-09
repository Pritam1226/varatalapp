import 'package:cloud_firestore/cloud_firestore.dart';

class ChatController {
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
    required String contactId,
    required String contactName,
  }) async {
    final messageData = {
      'sender': senderId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'contactId': contactId,
      'contactName': contactName,
    };

    await FirebaseFirestore.instance
        .collection('Chats')
        .doc(chatId)
        .collection('messages')
        .add(messageData);
  }

  String getChatId(String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return "${ids[0]}_${ids[1]}";
  }
}
