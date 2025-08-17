import 'dart:convert';
import 'package:encrypt/encrypt.dart';

class AESHelper {
  static String encrypt(String plainText, String key) {
    final keyBytes = Key.fromUtf8(key);
    final iv = IV.fromLength(
      16,
    ); // For simplicity, use a zero IV (not secure for real apps)
    final encrypter = Encrypter(AES(keyBytes, mode: AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return base64Encode(iv.bytes + encrypted.bytes);
  }

  static String decrypt(String encryptedBase64, String key) {
    final bytes = base64Decode(encryptedBase64);
    final iv = IV(bytes.sublist(0, 16));
    final encrypted = Encrypted(bytes.sublist(16));
    final keyBytes = Key.fromUtf8(key);
    final encrypter = Encrypter(AES(keyBytes, mode: AESMode.cbc));
    return encrypter.decrypt(encrypted, iv: iv);
  }
}
