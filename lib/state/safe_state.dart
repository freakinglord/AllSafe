import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/account.dart';
import '../services/safe_service.dart';

enum SafeStatus { locked, unlocking, unlocked }

class SafeState extends ChangeNotifier {
  SafeStatus _status = SafeStatus.locked;
  Safe _safe = const Safe();
  String? _imagePath;
  Uint8List? _imageBytes;
  String? _masterPassword;
  String? _error;
  bool _isDirty = false;
  bool _isSaving = false;
  bool _isDark = true;

  SafeStatus get status => _status;
  bool get isUnlocked => _status == SafeStatus.unlocked;
  bool get isLoading => _status == SafeStatus.unlocking;
  bool get isSaving => _isSaving;
  List<Account> get accounts => _safe.accounts;
  String? get error => _error;
  bool get isDirty => _isDirty;
  bool get isDark => _isDark;

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }

  String? get imagePath => _imagePath;
  bool get needsSavePath => isUnlocked && _imagePath == null;

  Future<void> openSafe(
      String imagePath, Uint8List imageBytes, String password) async {
    _status = SafeStatus.unlocking;
    _error = null;
    notifyListeners();

    try {
      final safe = await SafeService.loadSafe(imageBytes, password);
      _safe = safe;
      _imagePath = imagePath;
      _imageBytes = imageBytes;
      _masterPassword = password;
      _status = SafeStatus.unlocked;
      _isDirty = false;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _status = SafeStatus.locked;
    }
    notifyListeners();
  }

  void createSafe(Uint8List coverImageBytes, String password) {
    _safe = const Safe();
    _imageBytes = coverImageBytes;
    _masterPassword = password;
    _imagePath = null;
    _status = SafeStatus.unlocked;
    _isDirty = true;
    _error = null;
    notifyListeners();
  }

  Future<bool> saveToPath(String savePath) async {
    if (!isUnlocked || _imageBytes == null || _masterPassword == null) {
      return false;
    }
    _isSaving = true;
    notifyListeners();

    try {
      final newImageBytes =
          await SafeService.saveSafe(_imageBytes!, _safe, _masterPassword!);
      await File(savePath).writeAsBytes(newImageBytes);
      _imagePath = savePath;
      _imageBytes = newImageBytes;
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

  Future<bool> saveSafe() async {
    if (_imagePath == null) return false;
    return saveToPath(_imagePath!);
  }

  void lockSafe() {
    _safe = const Safe();
    _masterPassword = null;
    _imageBytes = null;
    _imagePath = null;
    _status = SafeStatus.locked;
    _error = null;
    _isDirty = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void addAccount(Account account) {
    _safe = _safe.copyWith(accounts: [..._safe.accounts, account]);
    _isDirty = true;
    notifyListeners();
  }

  void updateAccount(Account updated) {
    final accounts = _safe.accounts
        .map((a) => a.id == updated.id ? updated : a)
        .toList();
    _safe = _safe.copyWith(accounts: accounts);
    _isDirty = true;
    notifyListeners();
  }

  void deleteAccount(String id) {
    _safe = _safe.copyWith(
        accounts: _safe.accounts.where((a) => a.id != id).toList());
    _isDirty = true;
    notifyListeners();
  }
}
