import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import '../models/vault.dart';
import '../models/sync_config.dart';
import 'encryption_service.dart';

class StorageService {
  static const String _vaultKey = 'mi_xia_vault';
  static const String _masterPasswordHashKey = 'mi_xia_master_password_hash';
  static const String _masterPasswordKey = 'mi_xia_master_password';
  static const String _syncConfigKey = 'mi_xia_sync_config';
  static const String _settingsKey = 'mi_xia_settings';
  static const String _biometricEnabledKey = 'mi_xia_biometric_enabled';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    mOptions: MacOsOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  bool get _useFileStorage {
    if (kIsWeb) return false;
    return Platform.isMacOS || Platform.isWindows || Platform.isLinux;
  }

  Future<Directory> get _appSupportDir async {
    final dir = await getApplicationSupportDirectory();
    final appDir = Directory('${dir.path}/mi_xia');
    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }
    return appDir;
  }

  Future<File> _getSecureFile(String key) async {
    final dir = await _appSupportDir;
    return File('${dir.path}/$key.secure');
  }

  Future<void> _writeSecureData(String key, String value) async {
    if (_useFileStorage) {
      final file = await _getSecureFile(key);
      await file.writeAsString(value);
    } else {
      await _secureStorage.write(key: key, value: value);
    }
  }

  Future<String?> _readSecureData(String key) async {
    if (_useFileStorage) {
      try {
        final file = await _getSecureFile(key);
        if (await file.exists()) {
          return await file.readAsString();
        }
        return null;
      } catch (e) {
        debugPrint('Error reading secure file: $e');
        return null;
      }
    } else {
      return await _secureStorage.read(key: key);
    }
  }

  Future<void> _deleteSecureData(String key) async {
    if (_useFileStorage) {
      try {
        final file = await _getSecureFile(key);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('Error deleting secure file: $e');
      }
    } else {
      await _secureStorage.delete(key: key);
    }
  }

  Future<void> _deleteAllSecureData() async {
    if (_useFileStorage) {
      try {
        final dir = await _appSupportDir;
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      } catch (e) {
        debugPrint('Error deleting secure directory: $e');
      }
    } else {
      await _secureStorage.deleteAll();
    }
  }

  Future<void> saveVault(Vault vault, String masterPassword) async {
    final prefs = await SharedPreferences.getInstance();
    final vaultJson = jsonEncode(vault.toJson());
    final encrypted = EncryptionService.encrypt(vaultJson, masterPassword);
    await prefs.setString(_vaultKey, encrypted);
  }

  Future<Vault?> loadVault(String masterPassword) async {
    final prefs = await SharedPreferences.getInstance();
    final encrypted = prefs.getString(_vaultKey);

    if (encrypted == null) {
      return null;
    }

    try {
      final decrypted = EncryptionService.decrypt(encrypted, masterPassword);
      final json = jsonDecode(decrypted) as Map<String, dynamic>;
      return Vault.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  Future<void> saveMasterPasswordHash(String password) async {
    try {
      final hash = EncryptionService.hashPassword(password);
      await _writeSecureData(_masterPasswordHashKey, hash);
      debugPrint('saveMasterPasswordHash: success');
    } catch (e) {
      debugPrint('saveMasterPasswordHash error: $e');
      rethrow;
    }
  }

  Future<String?> getMasterPasswordHash() async {
    return await _readSecureData(_masterPasswordHashKey);
  }

  Future<bool> verifyMasterPassword(String password) async {
    final storedHash = await getMasterPasswordHash();
    if (storedHash == null) return false;
    return EncryptionService.verifyPassword(password, storedHash);
  }

  Future<bool> hasMasterPassword() async {
    final hash = await getMasterPasswordHash();
    return hash != null;
  }

  Future<void> saveSyncConfig(SyncConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_syncConfigKey, jsonEncode(config.toJson()));
  }

  Future<SyncConfig?> loadSyncConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_syncConfigKey);
    if (jsonStr == null) return null;

    try {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return SyncConfig.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  Future<void> saveSettings(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(settings));
  }

  Future<Map<String, dynamic>> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_settingsKey);
    if (jsonStr == null) return {};

    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  Future<void> saveMasterPassword(String password) async {
    await _writeSecureData(_masterPasswordKey, password);
  }

  Future<String?> getMasterPassword() async {
    return await _readSecureData(_masterPasswordKey);
  }

  Future<void> deleteMasterPassword() async {
    await _deleteSecureData(_masterPasswordKey);
  }

  Future<void> setBiometricEnabled(bool enabled, {String? masterPassword}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enabled);
    if (enabled && masterPassword != null) {
      await saveMasterPassword(masterPassword);
    } else if (!enabled) {
      await deleteMasterPassword();
    }
  }

  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await _deleteAllSecureData();
  }

  Future<String> exportVault(Vault vault) async {
    return jsonEncode(vault.toJson());
  }

  Future<Vault?> importVault(String jsonStr) async {
    try {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return Vault.fromJson(json);
    } catch (e) {
      return null;
    }
  }
}
