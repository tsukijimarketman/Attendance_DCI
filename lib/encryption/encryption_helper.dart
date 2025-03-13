import 'package:encrypt/encrypt.dart' as encrypt;
import 'dart:convert';

class EncryptionHelper {
  static final key = encrypt.Key.fromUtf8('Dci21Is294The2959Best20853Fred21'); // 32 chars key

  // Encrypt function
  static String encryptPassword(String password) {
    final iv = encrypt.IV.fromLength(16); // Generate a new IV each time
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    final encrypted = encrypter.encrypt(password, iv: iv);

    // Store both IV and encrypted text in Base64 (separated by ":")
    return "${base64.encode(iv.bytes)}:${base64.encode(encrypted.bytes)}";
  }

  // Decrypt function
  static String decryptPassword(String encryptedPassword) {
    try {
      final parts = encryptedPassword.split(":");
      if (parts.length != 2) {
        throw Exception("Invalid encrypted data format.");
      }

      final iv = encrypt.IV.fromBase64(parts[0]); // Retrieve IV
      final encryptedBytes = base64.decode(parts[1]); // Retrieve encrypted text

      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      final decrypted = encrypter.decrypt(encrypt.Encrypted(encryptedBytes), iv: iv);

      return decrypted;
    } catch (e) {
      print("Decryption error: $e");
      return "Decryption Failed"; // Handle error safely
    }
  }
}
