# Features / To Do
- [ ] Add import/export feature
- [ ] Add checkboxes to what kind of password to generate (e.g. weird characters, only alphanumeric, length)
- [ ] Add alert if password is re-used in other accounts
- [x] Allow users to change theme between light and dark through the whole interface
- [ ] If user wants to create a new safe on an existing safe image, it should detect the current image is already a safe and give warning before user attempt to overwrite it.

---

# Release2 — iOS Compatibility

- [x] Uncomment `platform :ios, '12.0'` in `ios/Podfile`
- [x] Add `path_provider` dependency to `pubspec.yaml` (needed for iOS Documents directory)
- [x] Replace `FilePicker.platform.saveFile()` in `lib/screens/account_list_screen.dart` — not supported on iOS; save to app Documents dir instead
- [x] Fix write-back path in `lib/state/safe_state.dart` — iOS file picker returns a temp path; save to Documents dir, not back to the temp picker path

---

# Missing Unit Tests

## CryptoService (`lib/services/crypto_service.dart`)
- [x] `encrypt` → `decrypt` round-trip returns original plaintext
- [x] `decrypt` with wrong password throws `WrongPasswordException`
- [x] `decrypt` with truncated payload throws `WrongPasswordException`
- [x] `encrypt` produces different ciphertext on each call (random salt/nonce)

## SteganographyService (`lib/services/steganography_service.dart`)
- [x] `embed` → `extract` round-trip returns original payload
- [x] `extract` on a plain PNG (no hidden data) throws `SteganographyException`
- [x] `embed` on a JPEG header throws `SteganographyException`
- [x] `embed` on an image too small for the payload throws `SteganographyException`
- [x] `extract` on a JPEG header throws `SteganographyException`

## SafeState (`lib/state/safe_state.dart`)
- [x] `addAccount` adds to `accounts` and sets `isDirty = true`
- [x] `updateAccount` replaces matching account and sets `isDirty = true`
- [x] `deleteAccount` removes matching account and sets `isDirty = true`
- [x] `lockSafe` clears accounts, password, image, resets `isDirty`
- [x] `createSafe` starts with empty accounts and `isDirty = true`
- [x] `needsSavePath` is true after `createSafe`, false after `saveToPath`
- [x] `openSafe` with a real embed+encrypt payload unlocks and populates accounts

## Account model (`lib/models/account.dart`)
- [x] `copyWith` preserves unchanged fields
- [x] `fromJson(toJson())` round-trip is lossless
- [x] `Account.create` generates a non-empty id

## Notes
- All tests go in `test/widget_test.dart` (or split into `test/crypto_test.dart`,
  `test/stego_test.dart`, `test/safe_state_test.dart`, `test/account_test.dart`)
- No Flutter widget testing needed — all logic is pure Dart
- Crypto and stego round-trips are highest priority (silent data corruption risk)
