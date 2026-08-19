import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:allsafe/models/account.dart';
import 'package:allsafe/services/crypto_service.dart';
import 'package:allsafe/services/steganography_service.dart';
import 'package:allsafe/state/safe_state.dart';

Uint8List _makePng(int w, int h) => img.encodePng(img.Image(width: w, height: h));

const _pw = 'testpass';
final _tiny = Uint8List(10);

void main() {
  late SafeState state;

  setUp(() => state = SafeState());

  test('addAccount adds to accounts and sets isDirty', () {
    state.createSafe(_tiny, _pw);
    final acc = Account(id: '1', name: 'A', password: 'p');
    state.addAccount(acc);
    expect(state.accounts, [acc]);
    expect(state.isDirty, isTrue);
  });

  test('updateAccount replaces matching account and sets isDirty', () {
    state.createSafe(_tiny, _pw);
    final acc = Account(id: '1', name: 'Old', password: 'p');
    state.addAccount(acc);
    final updated = Account(id: '1', name: 'New', password: 'p2');
    state.updateAccount(updated);
    expect(state.accounts.single.name, 'New');
    expect(state.isDirty, isTrue);
  });

  test('deleteAccount removes matching account and sets isDirty', () {
    state.createSafe(_tiny, _pw);
    state.addAccount(Account(id: '1', name: 'A', password: 'p'));
    state.deleteAccount('1');
    expect(state.accounts, isEmpty);
    expect(state.isDirty, isTrue);
  });

  test('lockSafe clears accounts, image, password and resets isDirty', () {
    state.createSafe(_tiny, _pw);
    state.addAccount(Account(id: '1', name: 'A', password: 'p'));
    state.lockSafe();
    expect(state.accounts, isEmpty);
    expect(state.isUnlocked, isFalse);
    expect(state.isDirty, isFalse);
    expect(state.imagePath, isNull);
  });

  test('createSafe starts with empty accounts and isDirty = true', () {
    state.createSafe(_tiny, _pw);
    expect(state.accounts, isEmpty);
    expect(state.isDirty, isTrue);
    expect(state.isUnlocked, isTrue);
  });

  test('createSafe with imagePath sets needsSavePath = false (iOS pre-determined path)', () {
    state.createSafe(_tiny, _pw, imagePath: '/docs/safe.png');
    expect(state.needsSavePath, isFalse);
    expect(state.imagePath, '/docs/safe.png');
  });

  test('needsSavePath is true after createSafe, false after saveToPath', () async {
    final png = _makePng(200, 200);
    state.createSafe(png, _pw);
    expect(state.needsSavePath, isTrue);

    final tmp = '${Directory.systemTemp.path}/allsafe_test_${DateTime.now().microsecondsSinceEpoch}.png';
    final ok = await state.saveToPath(tmp);
    expect(ok, isTrue);
    expect(state.needsSavePath, isFalse);

    // cleanup
    File(tmp).deleteSync();
  });

  test('openSafe with real embed+encrypt payload unlocks and populates accounts', () async {
    const password = 'opentest';
    final payload = utf8.encode(jsonEncode({
      'accounts': [
        {'id': '1', 'name': 'Test', 'email': '', 'username': '', 'password': 'pw', 'notes': ''}
      ]
    }));
    final encrypted = await CryptoService.encrypt(Uint8List.fromList(payload), password);
    final png = _makePng(200, 200);
    final embedded = SteganographyService.embed(png, encrypted);

    await state.openSafe('fake/path', embedded, password);

    expect(state.isUnlocked, isTrue);
    expect(state.accounts.length, 1);
    expect(state.accounts.first.name, 'Test');
  });
}
