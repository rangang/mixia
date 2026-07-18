import 'package:flutter/foundation.dart';
import '../models/vault.dart';
import '../models/password_entry.dart';
import '../models/sync_config.dart';
import '../services/storage_service.dart';
import '../services/biometric_service.dart';
import '../services/webdav_service.dart';
import '../services/webdav_service_stub.dart'
    if (dart.library.html) '../services/webdav_service_web.dart'
    if (dart.library.io) '../services/webdav_service_io.dart';

enum AuthState {
  initial,
  unauthenticated,
  authenticated,
  locked,
}

class SyncResult {
  final bool success;
  final String? errorMessage;
  final String? detail;

  SyncResult({
    required this.success,
    this.errorMessage,
    this.detail,
  });
}

class VaultProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService();

  Vault _vault = Vault();
  AuthState _authState = AuthState.initial;
  String _masterPassword = '';
  bool _isLoading = false;
  String? _errorMessage;
  SyncConfig? _syncConfig;
  bool _isDarkMode = true;
  bool _isSyncing = false;
  String? _syncStatusMessage;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  Vault get vault => _vault;
  AuthState get authState => _authState;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  SyncConfig? get syncConfig => _syncConfig;
  bool get isDarkMode => _isDarkMode;
  bool get isAuthenticated => _authState == AuthState.authenticated;
  bool get isSyncing => _isSyncing;
  String? get syncStatusMessage => _syncStatusMessage;
  StorageService get storageService => _storageService;
  bool get biometricAvailable => _biometricAvailable;
  bool get biometricEnabled => _biometricEnabled;

  Future<void> clearAllData() async {
    await _storageService.clearAll();
    _vault = Vault();
    _syncConfig = null;
    _masterPassword = '';
    _authState = AuthState.unauthenticated;
    _errorMessage = null;
    _biometricEnabled = false;
    notifyListeners();
  }

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    try {
      final hasPassword = await _storageService.hasMasterPassword();
      _authState = hasPassword ? AuthState.locked : AuthState.unauthenticated;
      _syncConfig = await _storageService.loadSyncConfig();
      final settings = await _storageService.loadSettings();
      _isDarkMode = settings['darkMode'] ?? true;
      _biometricEnabled = await _storageService.isBiometricEnabled();
      _biometricAvailable = await BiometricService.isBiometricAvailable();
    } catch (e) {
      _errorMessage = '初始化失败: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> setBiometricEnabled(bool enabled) async {
    try {
      if (enabled) {
        final available = await BiometricService.isBiometricAvailable();
        if (!available) {
          _errorMessage = '此设备不支持生物识别';
          notifyListeners();
          return false;
        }
        await _storageService.setBiometricEnabled(true, masterPassword: _masterPassword);
      } else {
        await _storageService.setBiometricEnabled(false);
      }
      _biometricEnabled = enabled;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = '设置生物识别失败: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> unlockWithBiometrics() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final authenticated = await BiometricService.authenticate(
        reason: '使用Touch ID/Face ID解锁密码库',
      );
      if (!authenticated) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final savedPassword = await _storageService.getMasterPassword();
      if (savedPassword == null) {
        _errorMessage = '未找到保存的密码，请使用主密码解锁';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      return await unlock(savedPassword);
    } catch (e) {
      _errorMessage = '生物识别解锁失败: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> setMasterPassword(String password) async {
    debugPrint('setMasterPassword: start');
    _isLoading = true;
    notifyListeners();
    try {
      debugPrint('setMasterPassword: saving hash...');
      await _storageService.saveMasterPasswordHash(password);
      debugPrint('setMasterPassword: hash saved');
      
      _masterPassword = password;
      _vault = Vault();
      
      debugPrint('setMasterPassword: saving vault...');
      await _storageService.saveVault(_vault, _masterPassword);
      debugPrint('setMasterPassword: vault saved');
      
      _biometricAvailable = await BiometricService.isBiometricAvailable();
      if (_biometricAvailable) {
        await _storageService.setBiometricEnabled(true, masterPassword: password);
        _biometricEnabled = true;
      }
      
      _authState = AuthState.authenticated;
      _errorMessage = null;
    } catch (e, stackTrace) {
      debugPrint('setMasterPassword error: $e');
      debugPrint('Stack trace: $stackTrace');
      _errorMessage = '设置主密码失败: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> unlock(String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final isValid = await _storageService.verifyMasterPassword(password);
      if (isValid) {
        _masterPassword = password;
        final vault = await _storageService.loadVault(password);
        if (vault != null) {
          _vault = vault;
          _authState = AuthState.authenticated;
          _errorMessage = null;
          return true;
        }
      }
      _errorMessage = '主密码错误';
      return false;
    } catch (e) {
      _errorMessage = '解锁失败: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void lock() {
    _authState = AuthState.locked;
    _masterPassword = '';
    _vault = Vault();
    notifyListeners();
  }

  Future<void> addEntry(PasswordEntry entry) async {
    _vault.addEntry(entry);
    await _saveVault();
    notifyListeners();
  }

  Future<void> updateEntry(PasswordEntry entry) async {
    _vault.updateEntry(entry);
    await _saveVault();
    notifyListeners();
  }

  Future<void> deleteEntry(String id) async {
    _vault.deleteEntry(id);
    await _saveVault();
    notifyListeners();
  }

  PasswordEntry? getEntry(String id) {
    return _vault.getEntry(id);
  }

  List<PasswordEntry> getEntriesByType(EntryType type) {
    return _vault.getEntriesByType(type);
  }

  List<PasswordEntry> searchEntries(String query) {
    return _vault.searchEntries(query);
  }

  List<PasswordEntry> getRecentEntries({int limit = 5}) {
    return _vault.getRecentEntries(limit: limit);
  }

  List<PasswordEntry> getFavoriteEntries() {
    return _vault.getFavoriteEntries();
  }

  Map<String, int> getStatistics() {
    return _vault.getStatistics();
  }

  Future<void> _saveVault() async {
    try {
      await _storageService.saveVault(_vault, _masterPassword);
    } catch (e) {
      _errorMessage = '保存失败: $e';
    }
  }

  Future<void> saveSyncConfig(SyncConfig config) async {
    _syncConfig = config;
    await _storageService.saveSyncConfig(config);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    await _storageService.saveSettings({'darkMode': value});
    notifyListeners();
  }

  Future<String> exportVault() async {
    return await _storageService.exportVault(_vault, _masterPassword);
  }

  Future<bool> importVault(String jsonStr) async {
    try {
      final imported = await _storageService.importVault(
        jsonStr,
        _masterPassword,
      );
      if (imported != null) {
        _vault = imported;
        await _saveVault();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = '导入失败: $e';
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<SyncResult> testWebDavConnection({SyncConfig? tempConfig}) async {
    final config = tempConfig ?? _syncConfig;
    if (config == null) {
      return SyncResult(success: false, errorMessage: '请先配置同步设置');
    }

    final urlValidation = _validateUrl(config.serverUrl);
    if (urlValidation != null) {
      return SyncResult(success: false, errorMessage: urlValidation);
    }

    _isSyncing = true;
    _syncStatusMessage = '正在测试连接...';
    notifyListeners();

    try {
      WebDavService webdavService = createService(config);
      final result = await webdavService.testConnection();

      _isSyncing = false;
      if (result.success) {
        _syncStatusMessage = '连接测试成功';
        notifyListeners();
        return SyncResult(success: true, detail: '连接测试成功！');
      } else {
        _syncStatusMessage = result.errorMessage;
        notifyListeners();
        return SyncResult(success: false, errorMessage: result.errorMessage);
      }
    } catch (e) {
      _isSyncing = false;
      _syncStatusMessage = '连接失败';
      notifyListeners();
      return SyncResult(success: false, errorMessage: '连接失败: ${e.toString()}');
    }
  }

  String? _validateUrl(String url) {
    final trimmedUrl = url.trim();
    if (trimmedUrl.isEmpty) {
      return '服务器地址不能为空';
    }
    if (!trimmedUrl.startsWith('http://') && !trimmedUrl.startsWith('https://')) {
      return '服务器地址必须以 http:// 或 https:// 开头';
    }
    try {
      final uri = Uri.parse(trimmedUrl);
      if (uri.host.isEmpty) {
        return '服务器地址格式不正确';
      }
    } catch (e) {
      return '服务器地址格式不正确';
    }
    return null;
  }

  Future<SyncResult> syncToCloud() async {
    if (_syncConfig == null || !_syncConfig!.enabled) {
      return SyncResult(success: false, errorMessage: '请先配置并启用同步');
    }

    _isSyncing = true;
    _syncStatusMessage = '正在同步到云端...';
    notifyListeners();

    try {
      WebDavService service = createService(_syncConfig!);

      final testResult = await service.testConnection();
      if (!testResult.success) {
        _isSyncing = false;
        _syncStatusMessage = testResult.errorMessage;
        notifyListeners();
        return SyncResult(success: false, errorMessage: testResult.errorMessage);
      }

      final encryptedContent = await _storageService.exportVault(
        _vault,
        _masterPassword,
      );

      final fileName = 'vault_${DateTime.now().millisecondsSinceEpoch}.json';
      final result = await service.uploadFile(fileName, encryptedContent);

      _isSyncing = false;
      if (result.success) {
        final updatedConfig = _syncConfig!.copyWith(lastSyncTime: DateTime.now());
        await saveSyncConfig(updatedConfig);
        _syncStatusMessage = '同步成功';
        notifyListeners();
        return SyncResult(success: true, detail: '同步完成！文件已上传到云端');
      } else {
        _syncStatusMessage = result.errorMessage;
        notifyListeners();
        return SyncResult(success: false, errorMessage: result.errorMessage);
      }
    } catch (e) {
      _isSyncing = false;
      _syncStatusMessage = '同步失败';
      notifyListeners();
      return SyncResult(success: false, errorMessage: '同步失败: ${e.toString()}');
    }
  }

  Future<SyncResult> syncFromCloud() async {
    if (_syncConfig == null || !_syncConfig!.enabled) {
      return SyncResult(success: false, errorMessage: '请先配置并启用同步');
    }

    _isSyncing = true;
    _syncStatusMessage = '正在从云端同步...';
    notifyListeners();

    try {
      WebDavService service = createService(_syncConfig!);

      final testResult = await service.testConnection();
      if (!testResult.success) {
        _isSyncing = false;
        _syncStatusMessage = testResult.errorMessage;
        notifyListeners();
        return SyncResult(success: false, errorMessage: testResult.errorMessage);
      }

      final files = await service.listFiles(_syncConfig!.path);
      if (files == null || files.isEmpty) {
        _isSyncing = false;
        _syncStatusMessage = '云端没有备份文件';
        notifyListeners();
        return SyncResult(success: false, errorMessage: '云端未找到备份文件');
      }

      final vaultFiles = files.where((f) => f.name.startsWith('vault_') && f.name.endsWith('.json')).toList();
      if (vaultFiles.isEmpty) {
        _isSyncing = false;
        _syncStatusMessage = '云端没有备份文件';
        notifyListeners();
        return SyncResult(success: false, errorMessage: '云端未找到备份文件');
      }

      vaultFiles.sort((a, b) => b.lastModified.compareTo(a.lastModified));
      final latestFile = vaultFiles.first;

      final content = await service.downloadFileContent(latestFile.path);
      if (content == null) {
        _isSyncing = false;
        _syncStatusMessage = '下载失败';
        notifyListeners();
        return SyncResult(success: false, errorMessage: '下载备份文件失败');
      }

      final imported = await _storageService.importVault(
        content,
        _masterPassword,
      );
      if (imported != null) {
        _vault = imported;
        await _saveVault();
        _isSyncing = false;
        _syncStatusMessage = '同步成功';
        notifyListeners();
        return SyncResult(success: true, detail: '已从云端恢复密码库');
      } else {
        _isSyncing = false;
        _syncStatusMessage = '导入失败';
        notifyListeners();
        return SyncResult(success: false, errorMessage: '导入备份文件失败');
      }
    } catch (e) {
      _isSyncing = false;
      _syncStatusMessage = '同步失败';
      notifyListeners();
      return SyncResult(success: false, errorMessage: '同步失败: ${e.toString()}');
    }
  }
}
