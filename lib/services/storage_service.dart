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

  final FlutterSecureStorage? _secureStorage;
  static Directory? _supportDir;

  StorageService() : _secureStorage = _shouldUseSecureStorage()
      ? const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock_this_device,
          ),
        )
      : null;

  static bool _shouldUseSecureStorage() {
    if (kIsWeb) return true;
    return !(Platform.isMacOS || Platform.isWindows || Platform.isLinux);
  }

  Future<Directory> _getSecureDir() async {
    if (_supportDir != null) return _supportDir!;
    final appSupportDir = await getApplicationSupportDirectory();
    _supportDir = Directory('${appSupportDir.path}/mi_xia');
    if (!await _supportDir!.exists()) {
      await _supportDir!.create(recursive: true);
    }
    return _supportDir!;
  }

  Future<File> _getSecureFile(String key) async {
    final dir = await _getSecureDir();
    return File('${dir.path}/$key.secure');
  }

  Future<void> _writeSecureData(String key, String value) async {
    if (_secureStorage != null) {
      await _secureStorage.write(key: key, value: value);
    } else {
      final file = await _getSecureFile(key);
      await file.writeAsString(value);
    }
  }

  Future<String?> _readSecureData(String key) async {
    if (_secureStorage != null) {
      return await _secureStorage.read(key: key);
    } else {
      final file = await _getSecureFile(key);
      if (await file.exists()) {
        return await file.readAsString();
      }
      return null;
    }
  }

  Future<void> _deleteSecureData(String key) async {
    if (_secureStorage != null) {
      await _secureStorage.delete(key: key);
    } else {
      final file = await _getSecureFile(key);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  Future<void> _deleteAllSecureData() async {
    if (_secureStorage != null) {
      await _secureStorage.deleteAll();
    }
    if (!kIsWeb &&
        (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
      final dir = await _getSecureDir();
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        _supportDir = null;
      }
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
      final vault = Vault.fromJson(json);
      if (!encrypted.startsWith('mx2:')) {
        await saveVault(vault, masterPassword);
      }
      return vault;
    } catch (e) {
      return null;
    }
  }

  Future<void> saveMasterPasswordHash(String password) async {
    try {
      final hash = EncryptionService.hashPassword(password);
      await _writeSecureData(_masterPasswordHashKey, hash);
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
    final verified = EncryptionService.verifyPassword(password, storedHash);
    if (verified && !storedHash.startsWith('argon2id:')) {
      await saveMasterPasswordHash(password);
    }
    return verified;
  }

  Future<bool> hasMasterPassword() async {
    final hash = await getMasterPasswordHash();
    return hash != null;
  }

  Future<void> saveSyncConfig(SyncConfig config) async {
    await _writeSecureData(_syncConfigKey, jsonEncode(config.toJson()));
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_syncConfigKey);
  }

  Future<SyncConfig?> loadSyncConfig() async {
    var jsonStr = await _readSecureData(_syncConfigKey);
    final prefs = await SharedPreferences.getInstance();
    final legacyJson = prefs.getString(_syncConfigKey);
    jsonStr ??= legacyJson;
    if (jsonStr == null) return null;

    try {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      final config = SyncConfig.fromJson(json);
      if (legacyJson != null) {
        await saveSyncConfig(config);
      }
      return config;
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

  Future<String> exportVault(Vault vault, String masterPassword) async {
    return EncryptionService.encrypt(
      jsonEncode(vault.toJson()),
      masterPassword,
    );
  }

  Future<Vault?> importVault(String backup, String masterPassword) async {
    try {
      final content = backup.trim();
      final plaintext = content.startsWith('mx2:')
          ? EncryptionService.decrypt(content, masterPassword)
          : content;
      final json = jsonDecode(plaintext) as Map<String, dynamic>;
      return Vault.fromJson(json);
    } catch (e) {
      return null;
    }
  }
}
