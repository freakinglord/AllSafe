# AllSafe

A steganography-based password manager inspired by *Mr. Robot* — your credentials are AES-256-GCM encrypted and hidden inside an ordinary PNG image using LSB steganography. To anyone who doesn't know the image is a safe, it looks like a normal picture.

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
  Ordinary-looking PNG  (your safe)
```

**Opening a safe** reverses the process: extract LSBs → decrypt blob → parse JSON accounts.

### Security properties

| Layer | Mechanism | Purpose |
|---|---|---|
| Encryption | AES-256-GCM | Confidentiality + integrity (wrong password = auth tag failure, not garbled data) |
| Key derivation | PBKDF2-SHA256, 100 000 iterations | Brute-force resistance |
| Steganography | 1-bit LSB per R/G/B channel | Obscurity — the safe looks like a photo |
| Salt & nonce | 16-byte salt, 12-byte nonce (random per save) | Prevents rainbow tables and nonce reuse |

A 1000×1000 PNG can hide ~375 KB of encrypted data (3 bits per pixel × 1 M pixels ÷ 8).

> **Note:** Steganography adds obscurity, not cryptographic security. The actual protection comes from AES-256-GCM. Keep your master password strong. And yes — the name's a nod to Gideon's company. Let's hope this safe holds up better than his did.

---

## Features

- Create a safe from any PNG image as the cover
- Add, edit, and delete accounts (name, email, username, password, notes)
- Strong password generator (24-character, cryptographically random)
- Reveal/hide password toggle in account detail view
- One-tap copy to clipboard for any field
- Save indicator — orange dot when there are unsaved changes
- Lock safe — clears all credentials from memory
- Search accounts by name, email, or username

---

## Getting started

### Prerequisites

#### All platforms

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.3.4 — follow the official install guide for your OS
- [Dart SDK](https://dart.dev/get-dart) ≥ 3.3.4 — bundled with Flutter, no separate install needed
- [Git](https://git-scm.com/downloads)

#### Linux

- **Clang / CMake / Ninja** — required by the Flutter Linux toolchain:
  ```bash
  sudo apt-get install clang cmake ninja-build
  ```
- **GTK 3 development libraries** — used by the file picker and Flutter's window system:
  ```bash
  sudo apt-get install libgtk-3-dev pkg-config liblzma-dev
  ```
- **xdg-desktop-portal** — enables the native file open/save dialog at runtime:
  ```bash
  sudo apt-get install xdg-desktop-portal
  ```
  On GNOME you also need `xdg-desktop-portal-gnome`; on KDE, `xdg-desktop-portal-kde`.
- Verify your setup: `flutter doctor -v`

#### macOS

- [Xcode](https://developer.apple.com/xcode/) ≥ 14 (install from the Mac App Store)
- Xcode command-line tools:
  ```bash
  xcode-select --install
  ```
- [CocoaPods](https://cocoapods.org/) — required for Flutter plugin dependencies:
  ```bash
  sudo gem install cocoapods
  ```
- Verify your setup: `flutter doctor -v`

> **Note:** Try running in VSCode if unable to run flutter in terminal and verified that is installed.

#### Windows

- [Visual Studio 2022](https://visualstudio.microsoft.com/) with the **Desktop development with C++** workload selected during installation
- Verify your setup: `flutter doctor -v`

### Clone and run

```bash
git clone https://github.com/freakinglord/AllSafe.git
cd AllSafe
flutter pub get
flutter run -d linux     # or -d macos / -d windows
```

### Run on iOS Simulator

```bash
open -a Simulator        # launch the simulator if not already open
flutter devices          # list available devices
flutter run -d "iPhone 16"  # replace with your device name from the list above
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

1. **Create a safe** — pick any PNG as your cover image, set a master password. The app creates an in-memory safe bound to that image.
2. **Add accounts** — tap the `+` button, fill in the details, optionally generate a strong password.
3. **Save** — tap the save icon. For a new safe you choose where to write the output PNG. For an existing safe it overwrites in place.
4. **Open a safe** — select the stego PNG, enter your master password.
5. **Lock** — clears all data from memory. The PNG on disk is your only persistent record.

---

## Project structure

```
lib/
├── main.dart                      # App entry point, light + dark themes
├── models/
│   └── account.dart               # Account and Safe data models
├── services/
│   ├── crypto_service.dart        # AES-256-GCM + PBKDF2
│   ├── steganography_service.dart # LSB embed / extract
│   └── safe_service.dart          # Orchestration (load / save safe)
├── state/
│   └── safe_state.dart            # ChangeNotifier state management
├── widgets/
│   └── password_field.dart        # Reusable show/hide password field
└── screens/
    ├── home_screen.dart            # Open or create safe
    ├── unlock_screen.dart          # Password entry + key derivation
    ├── account_list_screen.dart    # Searchable account list
    ├── account_detail_screen.dart  # View, copy, reveal, edit, delete
    └── add_edit_account_screen.dart
```

---

## Customization

### Changing the color scheme

Colors are defined as six constants at the top of `_buildLightTheme()` and `_buildDarkTheme()` in `lib/main.dart`. Changing them updates every AppBar, button, input, FAB, dialog, snackbar, and list tile automatically.

**Light theme**
```dart
const blue = Color(0xFF2B4D8C);    // primary — buttons, focus rings, icons
const bg = Color(0xFFF0F0F0);      // scaffold background
const surface = Color(0xFFFFFFFF); // cards, input fill
const border = Color(0xFFDDDDDD);  // borders and dividers
const textPrimary = Color(0xFF0D0D0D);
const textMuted = Color(0xFF666666);
```

**Dark theme**
```dart
const blue = Color(0xFF4A79C4);    // AllSafe blue
const bg = Color(0xFF0D1117);      // dark navy
const surface = Color(0xFF161C24); // card surfaces
const border = Color(0xFF20293A);  // dividers / borders
const textPrimary = Color(0xFFE8EEF6);
const textMuted = Color(0xFF6B7A8D);
```

Two additional colors are hardcoded outside those blocks:

| Color | Hex | Location |
|---|---|---|
| Error / delete red | `0xFFFF453A` | `main.dart` error borders, delete button in `account_detail_screen.dart` |
| Unsaved-changes dot | `0xFFFF8800` | `account_list_screen.dart` dirty indicator |

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

See [todo.md](todo.md).