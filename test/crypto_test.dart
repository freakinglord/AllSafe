import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:allsafe/services/crypto_service.dart';

void main() {
  final plaintext = Uint8List.fromList([1, 2, 3, 4, 5]);
  const password = 'correct-horse-battery-staple';

  test('encrypt → decrypt round-trip returns original plaintext', () async {
    final payload = await CryptoService.encrypt(plaintext, password);
    final result = await CryptoService.decrypt(payload, password);
    expect(result, equals(plaintext));
  });

  test('decrypt with wrong password throws WrongPasswordException', () async {
    final payload = await CryptoService.encrypt(plaintext, password);
    await expectLater(
      CryptoService.decrypt(payload, 'wrong-password'),
      throwsA(isA<WrongPasswordException>()),
    );
  });

  test('decrypt with truncated payload throws WrongPasswordException', () async {
    await expectLater(
      CryptoService.decrypt(Uint8List(10), password),
      throwsA(isA<WrongPasswordException>()),
    );
  });

  test('encrypt produces different ciphertext on each call', () async {
    final a = await CryptoService.encrypt(plaintext, password);
    final b = await CryptoService.encrypt(plaintext, password);
    expect(a, isNot(equals(b)));
  });
}
