import 'dart:convert';
import 'dart:typed_data';
import '../models/account.dart';
import 'crypto_service.dart';
import 'steganography_service.dart';

/// High-level orchestration: ties together steganography + encryption.
class VaultService {
  /// Extracts and decrypts the vault from a stego PNG image.
  /// Throws [SteganographyException] if no vault is found in the image.
  /// Throws [WrongPasswordException] if the master password is incorrect.
  static Future<Vault> loadVault(
      Uint8List imageBytes, String password) async {
    final encryptedPayload = SteganographyService.extract(imageBytes);
    final plaintext = await CryptoService.decrypt(encryptedPayload, password);
    return Vault.deserialize(utf8.decode(plaintext));
  }

  /// Encrypts the vault and embeds it into [imageBytes].
  /// Returns the modified PNG bytes. The original image bytes are not modified.
  static Future<Uint8List> saveVault(
      Uint8List imageBytes, Vault vault, String password) async {
    final plaintext =
        Uint8List.fromList(utf8.encode(vault.serialize()));
    final encryptedPayload =
        await CryptoService.encrypt(plaintext, password);
    return SteganographyService.embed(imageBytes, encryptedPayload);
  }

  /// Returns true if [imageBytes] contains a vault (by checking the magic header).
  static bool hasVault(Uint8List imageBytes) {
    try {
      SteganographyService.extract(imageBytes);
      return true;
    } on SteganographyException {
      return false;
    }
  }
}
