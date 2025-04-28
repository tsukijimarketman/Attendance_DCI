import 'package:encrypt/encrypt.dart' as encrypt;
import 'dart:convert';

/// This is a Dart class that provides methods for encrypting and decrypting
/// passwords using AES encryption. It uses the `encrypt` package for the
/// encryption process and Base64 encoding for the encrypted data.

/// Helper class that provides static methods to encrypt and decrypt passwords
/// using AES encryption.
class EncryptionHelper {
  // Define a static AES key (must be exactly 32 characters for AES-256).
  static final key =
      encrypt.Key.fromUtf8('Dci21Is294The2959Best20853Fred21'); // 32 chars key

  /// Encrypts a given plain text password and returns a string containing
  /// both the IV and the encrypted data, separated by a colon ":".
  static String encryptPassword(String password) {
    // Generate a random Initialization Vector (IV) of 16 bytes (128 bits).
    final iv = encrypt.IV.fromLength(16);

    // Create an AES encrypter instance using the predefined key.
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    // Encrypt the password using AES and the generated IV.
    final encrypted = encrypter.encrypt(password, iv: iv);

    // Encode the IV and the encrypted data separately in Base64.
    // Combine them with ":" so they can be separated during decryption.
    return "${base64.encode(iv.bytes)}:${base64.encode(encrypted.bytes)}";
  }

  /// Decrypts an encrypted password string (containing IV and encrypted text)
  /// and returns the original plain text password.
  static String decryptPassword(String encryptedPassword) {
    try {
      // Split the incoming encrypted password into IV and encrypted data parts.
      final parts = encryptedPassword.split(":");

      // Check if the format is correct (must have exactly 2 parts).
      if (parts.length != 2) {
        throw Exception(
            "Invalid encrypted data format."); // Throw error if format is wrong.
      }

      // Decode the IV part from Base64 back to bytes.
      final iv = encrypt.IV.fromBase64(parts[0]); // Retrieve IV

      // Decode the encrypted text part from Base64 back to bytes.
      final encryptedBytes = base64.decode(parts[1]); // Retrieve encrypted text

      // Create an AES encrypter instance again using the same key.
      final encrypter = encrypt.Encrypter(encrypt.AES(key));

      // Decrypt the encrypted bytes using the decoded IV.
      final decrypted =
          encrypter.decrypt(encrypt.Encrypted(encryptedBytes), iv: iv);

      // Return the decrypted plain text password.

      return decrypted;
    } catch (e) {
      // If any error occurs during decryption, print it and return a failure message.
      return "Decryption Failed"; // Safe fallback response.
    }
  }
}
