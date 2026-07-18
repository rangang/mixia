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
    wOptions: WindowsOptions(),
    lOptions: LinuxOptions(),
  );

  Future<void> _writeSecureData(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
    final legacyFile = await _legacyFile(key);
    if (legacyFile != null && await legacyFile.exists()) {
      await legacyFile.delete();
    }
  }

  Future<String?> _readSecureData(String key) async {
    final secureValue = await _secureStorage.read(key: key);
    if (secureValue != null) return secureValue;
    final legacyFile = await _legacyFile(key);
    if (legacyFile != null && await legacyFile.exists()) {
      final legacyValue = await legacyFile.readAsString();
      await _secureStorage.write(key: key, value: legacyValue);
      await legacyFile.delete();
      return legacyValue;
    }
    return null;
  }

  Future<void> _deleteSecureData(String key) async {
    await _secureStorage.delete(key: key);
    final legacyFile = await _legacyFile(key);
    if (legacyFile != null && await legacyFile.exists()) {
      await legacyFile.delete();
    }
  }

  Future<void> _deleteAllSecureData() async {
    await _secureStorage.deleteAll();
    if (!kIsWeb &&
        (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
      final supportDir = await getApplicationSupportDirectory();
      final legacyDir = Directory('${supportDir.path}/mi_xia');
      if (await legacyDir.exists()) {
        await legacyDir.delete(recursive: true);
      }
    }
  }

  Future<File?> _legacyFile(String key) async {
    if (kIsWeb ||
        !(Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
      return null;
    }
    final supportDir = await getApplicationSupportDirectory();
    return File('${supportDir.path}/mi_xia/$key.secure');
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
