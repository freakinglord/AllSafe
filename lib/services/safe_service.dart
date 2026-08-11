import 'dart:convert';
import 'dart:typed_data';
import '../models/account.dart';
import 'crypto_service.dart';
import 'steganography_service.dart';

class SafeService {
  static Future<Safe> loadSafe(Uint8List imageBytes, String password) async {
    final encryptedPayload = SteganographyService.extract(imageBytes);
    final plaintext = await CryptoService.decrypt(encryptedPayload, password);
    return Safe.deserialize(utf8.decode(plaintext));
  }

  static Future<Uint8List> saveSafe(
      Uint8List imageBytes, Safe safe, String password) async {
    final plaintext = Uint8List.fromList(utf8.encode(safe.serialize()));
    final encryptedPayload = await CryptoService.encrypt(plaintext, password);
    return SteganographyService.embed(imageBytes, encryptedPayload);
  }

  static bool hasSafe(Uint8List imageBytes) {
    try {
      SteganographyService.extract(imageBytes);
      return true;
    } on SteganographyException {
      return false;
    }
  }
}
