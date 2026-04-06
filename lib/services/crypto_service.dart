import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';
import 'package:cryptography/cryptography.dart';

class WrongPasswordException implements Exception {
  @override
  String toString() =>
      'Incorrect master password or corrupted vault data.';
}

class CryptoService {
  static const int _saltLength = 16; // PBKDF2 salt (128-bit)
  static const int _nonceLength = 12; // AES-GCM nonce (96-bit)
  static const int _macLength = 16; // AES-GCM authentication tag (128-bit)

  static Uint8List _randomBytes(int length) {
    final rng = Random.secure();
    return Uint8List.fromList(List.generate(length, (_) => rng.nextInt(256)));
  }

  /// Derives a 256-bit key from [password] and [salt] using PBKDF2-SHA256
  /// with 100,000 iterations. Runs in a separate isolate to avoid blocking UI.
  static Future<List<int>> _deriveKeyBytes(
      String password, List<int> salt) async {
    return Isolate.run(() async {
      final pbkdf2 = Pbkdf2(
        macAlgorithm: Hmac.sha256(),
        iterations: 100000,
        bits: 256,
      );
      final secretKey = await pbkdf2.deriveKey(
        secretKey: SecretKey(utf8.encode(password)),
        nonce: salt,
      );
      return await secretKey.extractBytes();
    });
  }

  /// Encrypts [plaintext] with [password].
  ///
  /// Output layout (all concatenated):
  ///   salt (16) | nonce (12) | mac (16) | ciphertext (N)
  static Future<Uint8List> encrypt(
      Uint8List plaintext, String password) async {
    final salt = _randomBytes(_saltLength);
    final keyBytes = await _deriveKeyBytes(password, salt);

    final aesGcm = AesGcm.with256bits();
    final secretKey = SecretKey(keyBytes);
    final secretBox = await aesGcm.encrypt(plaintext, secretKey: secretKey);

    final output = BytesBuilder(copy: false);
    output.add(salt);
    output.add(secretBox.nonce);
    output.add(secretBox.mac.bytes);
    output.add(secretBox.cipherText);
    return output.toBytes();
  }

  /// Decrypts a payload produced by [encrypt].
  /// Throws [WrongPasswordException] if the password is wrong or data is corrupt.
  static Future<Uint8List> decrypt(
      Uint8List payload, String password) async {
    if (payload.length < _saltLength + _nonceLength + _macLength + 1) {
      throw WrongPasswordException();
    }

    int o = 0;
    final salt = payload.sublist(o, o += _saltLength);
    final nonce = payload.sublist(o, o += _nonceLength);
    final mac = payload.sublist(o, o += _macLength);
    final ciphertext = payload.sublist(o);

    final keyBytes = await _deriveKeyBytes(password, salt);
    final secretKey = SecretKey(keyBytes);
    final aesGcm = AesGcm.with256bits();
    final secretBox = SecretBox(ciphertext, nonce: nonce, mac: Mac(mac));

    try {
      final plain = await aesGcm.decrypt(secretBox, secretKey: secretKey);
      return Uint8List.fromList(plain);
    } on SecretBoxAuthenticationError {
      throw WrongPasswordException();
    }
  }
}
