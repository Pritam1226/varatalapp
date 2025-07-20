import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';

class EncryptionHelper {
  final Key key;
  final IV iv = IV.fromLength(16); // Use a better IV strategy in production

  EncryptionHelper(String secretKey)
      : key = Key.fromUtf8(secretKey.padRight(32).substring(0, 32));

  String encryptText(String plainText) {
    final encrypter = Encrypter(AES(key));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return encrypted.base64;
  }

  String decryptText(String encryptedText) {
    final encrypter = Encrypter(AES(key));
    return encrypter.decrypt(Encrypted.fromBase64(encryptedText), iv: iv);
  }

  Uint8List encryptBytes(Uint8List bytes) {
    final encrypter = Encrypter(AES(key));
    return encrypter.encryptBytes(bytes, iv: iv).bytes;
  }

  List<int> decryptBytes(Uint8List encryptedBytes) {
    final encrypter = Encrypter(AES(key));
    return encrypter.decryptBytes(Encrypted(encryptedBytes), iv: iv);
  }
}
