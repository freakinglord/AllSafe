# Missing Unit Tests

## CryptoService (`lib/services/crypto_service.dart`)
- [ ] `encrypt` → `decrypt` round-trip returns original plaintext
- [ ] `decrypt` with wrong password throws `WrongPasswordException`
- [ ] `decrypt` with truncated payload throws `WrongPasswordException`
- [ ] `encrypt` produces different ciphertext on each call (random salt/nonce)

## SteganographyService (`lib/services/steganography_service.dart`)
- [ ] `embed` → `extract` round-trip returns original payload
- [ ] `extract` on a plain PNG (no hidden data) throws `SteganographyException`
- [ ] `embed` on a JPEG header throws `SteganographyException`
- [ ] `embed` on an image too small for the payload throws `SteganographyException`
- [ ] `extract` on a JPEG header throws `SteganographyException`

## SafeState (`lib/state/safe_state.dart`)
- [ ] `addAccount` adds to `accounts` and sets `isDirty = true`
- [ ] `updateAccount` replaces matching account and sets `isDirty = true`
- [ ] `deleteAccount` removes matching account and sets `isDirty = true`
- [ ] `lockSafe` clears accounts, password, image, resets `isDirty`
- [ ] `createSafe` starts with empty accounts and `isDirty = true`
- [ ] `needsSavePath` is true after `createSafe`, false after `saveToPath`
- [ ] `openSafe` with a real embed+encrypt payload unlocks and populates accounts

## Account model (`lib/models/account.dart`)
- [ ] `copyWith` preserves unchanged fields
- [ ] `fromJson(toJson())` round-trip is lossless
- [ ] `Account.create` generates a non-empty id

## Notes
- All tests go in `test/widget_test.dart` (or split into `test/crypto_test.dart`,
  `test/stego_test.dart`, `test/safe_state_test.dart`, `test/account_test.dart`)
- No Flutter widget testing needed — all logic is pure Dart
- Crypto and stego round-trips are highest priority (silent data corruption risk)
