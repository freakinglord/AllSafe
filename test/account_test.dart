import 'package:flutter_test/flutter_test.dart';
import 'package:allsafe/models/account.dart';

void main() {
  final base = Account(id: '1', name: 'Alice', email: 'a@b.com', username: 'alice', password: 'pw', notes: 'n');

  test('copyWith preserves unchanged fields', () {
    final updated = base.copyWith(name: 'new');
    expect(updated.id, base.id);
    expect(updated.name, 'new');
    expect(updated.email, base.email);
    expect(updated.username, base.username);
    expect(updated.password, base.password);
    expect(updated.notes, base.notes);
  });

  test('fromJson(toJson()) round-trip is lossless', () {
    final restored = Account.fromJson(base.toJson());
    expect(restored.id, base.id);
    expect(restored.name, base.name);
    expect(restored.email, base.email);
    expect(restored.username, base.username);
    expect(restored.password, base.password);
    expect(restored.notes, base.notes);
  });

  test('Account.create generates a non-empty id', () {
    final account = Account.create(name: 'x', password: 'y');
    expect(account.id.isNotEmpty, true);
  });
}
