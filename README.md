# Stegan Vault

A steganography-based password manager inspired by *Mr. Robot* — your credentials are AES-256-GCM encrypted and hidden inside an ordinary PNG image using LSB steganography. To anyone who doesn't know the image is a vault, it looks like a normal picture.

---

## How it works

```
Your accounts (JSON)
        │
        ▼
  AES-256-GCM encryption  ◄──  Master password  ──►  PBKDF2-SHA256 key derivation
        │
        ▼
  Encrypted blob
        │
        ▼
  LSB steganography  ──►  Each bit written to the least-significant bit of R/G/B channels
        │
        ▼
  Ordinary-looking PNG  (your vault)
```

**Opening a vault** reverses the process: extract LSBs → decrypt blob → parse JSON accounts.

### Security properties

| Layer | Mechanism | Purpose |
|---|---|---|
| Encryption | AES-256-GCM | Confidentiality + integrity (wrong password = auth tag failure, not garbled data) |
| Key derivation | PBKDF2-SHA256, 100 000 iterations | Brute-force resistance |
| Steganography | 1-bit LSB per R/G/B channel | Obscurity — the vault looks like a photo |
| Salt & nonce | 16-byte salt, 12-byte nonce (random per save) | Prevents rainbow tables and nonce reuse |

A 1000×1000 PNG can hide ~375 KB of encrypted data (3 bits per pixel × 1 M pixels ÷ 8).

> **Note:** Steganography adds obscurity, not cryptographic security. The actual protection comes from AES-256-GCM. Keep your master password strong.

---

## Features

- Create a vault from any PNG image as the cover
- Add, edit, and delete accounts (name, email, username, password, notes)
- Strong password generator (24-character, cryptographically random)
- Reveal/hide password toggle in account detail view
- One-tap copy to clipboard for any field
- Save indicator — orange dot when there are unsaved changes
- Lock vault — clears all credentials from memory
- Search accounts by name, email, or username

---

## Getting started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.3.4
- For **Linux**: GTK development libraries and `xdg-desktop-portal` (for the file picker)
- For **macOS**: Xcode

### Clone and run

```bash
git clone https://github.com/your-username/new-password-manager.git
cd new-password-manager
flutter pub get
flutter run -d linux     # or -d macos / -d windows
```

### Build a release binary

```bash
# Linux
flutter build linux

# macOS
flutter build macos
```

---

## Usage

1. **Create a vault** — pick any PNG as your cover image, set a master password. The app creates an in-memory vault bound to that image.
2. **Add accounts** — tap the `+` button, fill in the details, optionally generate a strong password.
3. **Save** — tap the save icon. For a new vault you choose where to write the output PNG. For an existing vault it overwrites in place.
4. **Open a vault** — select the stego PNG, enter your master password.
5. **Lock** — clears all data from memory. The PNG on disk is your only persistent record.

---

## Project structure

```
lib/
├── main.dart                      # App entry point, dark theme
├── models/
│   └── account.dart               # Account and Vault data models
├── services/
│   ├── crypto_service.dart        # AES-256-GCM + PBKDF2
│   ├── steganography_service.dart # LSB embed / extract
│   └── vault_service.dart         # Orchestration (load / save vault)
├── state/
│   └── vault_state.dart           # ChangeNotifier state management
├── widgets/
│   └── password_field.dart        # Reusable show/hide password field
└── screens/
    ├── home_screen.dart            # Open or create vault
    ├── unlock_screen.dart          # Password entry + key derivation
    ├── account_list_screen.dart    # Searchable account list
    ├── account_detail_screen.dart  # View, copy, reveal, edit, delete
    └── add_edit_account_screen.dart
```

---

## Customization

### Changing the color scheme

All theme colors are defined as six constants at the top of `_buildTheme()` in `lib/main.dart`:

```dart
const green = Color(0xFF00FF41);       // accent / primary — buttons, focus rings, icons
const bg = Color(0xFF0A0A0A);          // scaffold background
const surface = Color(0xFF141414);     // cards, input fill, password generator button
const border = Color(0xFF2A2A2A);      // borders and dividers
const textPrimary = Color(0xFFE0E0E0); // main body text
const textMuted = Color(0xFF555555);   // labels, icons, subtitles
```

Changing these six values updates every AppBar, button, input field, FAB, dialog, snackbar, and list tile automatically.

Two additional colors are hardcoded outside that block:

| Color | Hex | Location |
|---|---|---|
| Error / delete red | `0xFFFF4444` | `main.dart` error borders, delete button in `account_detail_screen.dart` |
| Unsaved-changes dot | `0xFFFF8800` | `account_list_screen.dart` dirty indicator |

#### Example — blue cyberpunk theme

```dart
const green = Color(0xFF00CFFF);   // cyan-blue accent
const bg = Color(0xFF080C14);      // very dark navy
const surface = Color(0xFF0D1520); // dark blue surface
const border = Color(0xFF1A2840);  // subtle blue border
const textPrimary = Color(0xFFCFE2FF);
const textMuted = Color(0xFF4A6A8A);
```

---

## Dependencies

| Package | Purpose |
|---|---|
| [`cryptography`](https://pub.dev/packages/cryptography) | AES-256-GCM encryption and PBKDF2 key derivation |
| [`image`](https://pub.dev/packages/image) | PNG decoding/encoding and pixel-level manipulation |
| [`file_picker`](https://pub.dev/packages/file_picker) | Native file open/save dialogs |
| [`provider`](https://pub.dev/packages/provider) | State management |

---

## Supported platforms

| Platform | Status |
|---|---|
| Linux | ✅ Primary target |
| macOS | ✅ Supported |
| Windows | ✅ Supported |
| Android / iOS | ⚠️ Not tested (file picker behavior may differ) |
| Web | ❌ Not supported (file system access limitations) |


## To Do
- [ ] Add import/export feature
- [ ] Add checkboxes to what kind of password to generate (e.g. weird characters, only alphanumeric, length)
- [ ] Add alert if password is re-used in other accounts