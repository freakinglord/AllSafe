import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/account.dart';
import '../services/crypto_service.dart';
import '../services/steganography_service.dart';

enum SafeStatus { locked, unlocking, unlocked }

class SafeState extends ChangeNotifier {
  SafeStatus _status = SafeStatus.locked;
  List<Account> _accounts = const [];
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
  List<Account> get accounts => _accounts;
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
      final encryptedPayload = SteganographyService.extract(imageBytes);
      final plaintext = await CryptoService.decrypt(encryptedPayload, password);
      final json = jsonDecode(utf8.decode(plaintext)) as Map<String, dynamic>;
      _accounts = (json['accounts'] as List<dynamic>)
          .map((e) => Account.fromJson(e as Map<String, dynamic>))
          .toList();
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

  void createSafe(Uint8List coverImageBytes, String password, {String? imagePath}) {
    _accounts = const [];
    _imageBytes = coverImageBytes;
    _masterPassword = password;
    _imagePath = imagePath;
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
      final json = jsonEncode({'accounts': _accounts.map((a) => a.toJson()).toList()});
      final plaintext = Uint8List.fromList(utf8.encode(json));
      final encrypted = await CryptoService.encrypt(plaintext, _masterPassword!);
      final newImageBytes = SteganographyService.embed(_imageBytes!, encrypted);
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

  void lockSafe() {
    _accounts = const [];
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
    _accounts = [..._accounts, account];
    _isDirty = true;
    notifyListeners();
  }

  void updateAccount(Account updated) {
    _accounts = _accounts.map((a) => a.id == updated.id ? updated : a).toList();
    _isDirty = true;
    notifyListeners();
  }

  void deleteAccount(String id) {
    _accounts = _accounts.where((a) => a.id != id).toList();
    _isDirty = true;
    notifyListeners();
  }
}
