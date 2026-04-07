import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/account.dart';
import '../services/vault_service.dart';

enum VaultStatus { locked, unlocking, unlocked }

class VaultState extends ChangeNotifier {
  VaultStatus _status = VaultStatus.locked;
  Vault _vault = const Vault();
  String? _imagePath;
  Uint8List? _imageBytes; // Current PNG bytes (stego or cover image)
  String? _masterPassword;
  String? _error;
  bool _isDirty = false;
  bool _isSaving = false;
  bool _isDark = true;

  // ── Getters ──────────────────────────────────────────────────────────────

  VaultStatus get status => _status;
  bool get isUnlocked => _status == VaultStatus.unlocked;
  bool get isLoading => _status == VaultStatus.unlocking;
  bool get isSaving => _isSaving;
  List<Account> get accounts => _vault.accounts;
  String? get error => _error;
  bool get isDirty => _isDirty;
  bool get isDark => _isDark;

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }

  /// Path to the current vault PNG on disk. Null if vault was just created
  /// and has never been saved.
  String? get imagePath => _imagePath;

  /// True when vault is open but hasn't been saved to a file yet (new vault).
  bool get needsSavePath => isUnlocked && _imagePath == null;

  // ── Vault lifecycle ───────────────────────────────────────────────────────

  /// Opens and decrypts an existing vault from [imageBytes] (a stego PNG).
  Future<void> openVault(
      String imagePath, Uint8List imageBytes, String password) async {
    _status = VaultStatus.unlocking;
    _error = null;
    notifyListeners();

    try {
      final vault = await VaultService.loadVault(imageBytes, password);
      _vault = vault;
      _imagePath = imagePath;
      _imageBytes = imageBytes;
      _masterPassword = password;
      _status = VaultStatus.unlocked;
      _isDirty = false;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _status = VaultStatus.locked;
    }
    notifyListeners();
  }

  /// Creates a new empty vault using [coverImageBytes] as the carrier PNG.
  /// The vault is held in memory; call [saveToPath] to persist it.
  void createVault(Uint8List coverImageBytes, String password) {
    _vault = const Vault();
    _imageBytes = coverImageBytes;
    _masterPassword = password;
    _imagePath = null;
    _status = VaultStatus.unlocked;
    _isDirty = true;
    _error = null;
    notifyListeners();
  }

  /// Encrypts the vault and writes it to [savePath].
  /// Returns true on success, false on failure (check [error]).
  Future<bool> saveToPath(String savePath) async {
    if (!isUnlocked || _imageBytes == null || _masterPassword == null) {
      return false;
    }
    _isSaving = true;
    notifyListeners();

    try {
      final newImageBytes =
          await VaultService.saveVault(_imageBytes!, _vault, _masterPassword!);
      await File(savePath).writeAsBytes(newImageBytes);
      _imagePath = savePath;
      _imageBytes = newImageBytes; // future saves embed into this image
      _isDirty = false;
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Saves to the existing [imagePath]. Requires a prior call to [saveToPath]
  /// or [openVault] (both set [imagePath]).
  Future<bool> saveVault() async {
    if (_imagePath == null) return false;
    return saveToPath(_imagePath!);
  }

  /// Clears vault data from memory. The on-disk image is unaffected.
  void lockVault() {
    _vault = const Vault();
    _masterPassword = null;
    _imageBytes = null;
    _imagePath = null;
    _status = VaultStatus.locked;
    _error = null;
    _isDirty = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ── Account mutations ─────────────────────────────────────────────────────

  void addAccount(Account account) {
    _vault = _vault.copyWith(accounts: [..._vault.accounts, account]);
    _isDirty = true;
    notifyListeners();
  }

  void updateAccount(Account updated) {
    final accounts = _vault.accounts
        .map((a) => a.id == updated.id ? updated : a)
        .toList();
    _vault = _vault.copyWith(accounts: accounts);
    _isDirty = true;
    notifyListeners();
  }

  void deleteAccount(String id) {
    _vault = _vault.copyWith(
        accounts: _vault.accounts.where((a) => a.id != id).toList());
    _isDirty = true;
    notifyListeners();
  }
}
