import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/sync_config.dart';
import '../providers/vault_provider.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';

class SyncSettingsScreen extends StatefulWidget {
  const SyncSettingsScreen({super.key});

  @override
  State<SyncSettingsScreen> createState() => _SyncSettingsScreenState();
}

class _SyncSettingsScreenState extends State<SyncSettingsScreen> {
  final _serverUrlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _pathController = TextEditingController(text: '/mi_xia/');

  SyncType _selectedType = SyncType.webdav;
  bool _autoSync = false;
  bool _obscurePassword = true;
  String? _lastSyncTime;
  String? _syncResultMessage;
  bool _syncResultSuccess = false;

  @override
  void initState() {
    super.initState();
    final config = context.read<VaultProvider>().syncConfig;
    if (config != null) {
      _serverUrlController.text = config.serverUrl;
      _usernameController.text = config.username;
      _passwordController.text = config.password;
      _pathController.text = config.path;
      _selectedType = config.type;
      _autoSync = config.autoSync;
      _lastSyncTime = config.lastSyncTime?.toString();
    }
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('同步设置'),
      ),
      body: Consumer<VaultProvider>(
        builder: (context, provider, _) {
          if (Responsive.isDesktop(context)) {
            return Center(
              child: SizedBox(
                width: 800,
                child: ListView(
                  padding: ResponsivePadding.all(context),
                  children: _buildSettingsList(provider),
                ),
              ),
            );
          }
          return ListView(
            padding: ResponsivePadding.all(context),
            children: _buildSettingsList(provider),
          );
        },
      ),
    );
  }

  List<Widget> _buildSettingsList(VaultProvider provider) {
    return [
      _buildProtocolSelector(),
      const SizedBox(height: 24),
      _buildConnectionSettings(),
      const SizedBox(height: 24),
      _buildSyncOptions(),
      const SizedBox(height: 24),
      _buildSyncStatus(provider),
      const SizedBox(height: 24),
      if (_syncResultMessage != null) _buildSyncResult(),
      const SizedBox(height: 32),
      _buildActionButtons(provider),
    ];
  }

  Future<void> _saveConfig() async {
    if (_serverUrlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入服务器地址')),
      );
      return;
    }

    final config = SyncConfig(
      type: _selectedType,
      serverUrl: _serverUrlController.text,
      username: _usernameController.text,
      password: _passwordController.text,
      path: _pathController.text,
      autoSync: _autoSync,
      enabled: true,
    );

    await context.read<VaultProvider>().saveSyncConfig(config);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('同步配置已保存')),
      );
    }
  }

  Future<void> _testConnection() async {
    final url = _serverUrlController.text.trim();
    
    // URL 验证
    if (url.isEmpty) {
      _showError('请输入服务器地址');
      return;
    }
    
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      _showError('服务器地址必须以 http:// 或 https:// 开头');
      return;
    }
    
    try {
      final uri = Uri.parse(url);
      if (uri.host.isEmpty) {
        _showError('服务器地址格式不正确');
        return;
      }
    } catch (e) {
      _showError('服务器地址格式不正确');
      return;
    }

    final tempConfig = SyncConfig(
      type: _selectedType,
      serverUrl: _serverUrlController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      path: _pathController.text.trim().isEmpty ? '/mi_xia/' : _pathController.text.trim(),
      autoSync: _autoSync,
      enabled: true,
    );

    final provider = context.read<VaultProvider>();
    final result = await provider.testWebDavConnection(tempConfig: tempConfig);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.success ? result.detail! : result.errorMessage!),
          backgroundColor: result.success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  Future<void> _syncToCloud() async {
    final provider = context.read<VaultProvider>();
    final result = await provider.syncToCloud();

    if (mounted) {
      setState(() {
        _syncResultMessage = result.success ? result.detail! : result.errorMessage!;
        _syncResultSuccess = result.success;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_syncResultMessage!),
          backgroundColor: result.success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  Future<void> _syncFromCloud() async {
    final provider = context.read<VaultProvider>();
    final result = await provider.syncFromCloud();

    if (mounted) {
      setState(() {
        _syncResultMessage = result.success ? result.detail! : result.errorMessage!;
        _syncResultSuccess = result.success;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_syncResultMessage!),
          backgroundColor: result.success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  Widget _buildProtocolSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '同步协议',
          style: TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _buildProtocolCard(
          type: SyncType.webdav,
          title: 'WebDAV',
          subtitle: '支持坚果云、Nextcloud、群晖/威联通NAS等',
          icon: Icons.cloud,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.bg2,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.rule),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.muted, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'WebDAV是通用云同步协议，大多数私有云存储均支持',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProtocolCard({
    required SyncType type,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = true;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.accent.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.accent,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: AppColors.accent),
        ],
      ),
    );
  }

  Widget _buildConnectionSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '连接设置',
          style: TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _serverUrlController,
          decoration: const InputDecoration(
            labelText: 'WebDAV 服务器地址',
            hintText: 'https://dav.example.com',
            prefixIcon: const Icon(Icons.link),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _usernameController,
          decoration: const InputDecoration(
            labelText: '用户名',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: '密码',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: AppColors.muted,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _pathController,
          decoration: const InputDecoration(
            labelText: '远程路径',
            hintText: '/mi_xia/',
            prefixIcon: Icon(Icons.folder_outlined),
          ),
        ),
      ],
    );
  }

  Widget _buildSyncOptions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.rule),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '同步选项',
            style: TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '自动同步',
                      style: TextStyle(color: AppColors.ink),
                    ),
                    Text(
                      '定期自动同步密码库',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _autoSync,
                onChanged: (value) {
                  setState(() {
                    _autoSync = value;
                  });
                },
                activeColor: AppColors.accent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSyncStatus(VaultProvider provider) {
    final lastSync = provider.syncConfig?.lastSyncTime;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.rule),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '同步状态',
            style: TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: provider.syncConfig?.enabled == true 
                      ? AppColors.success 
                      : AppColors.muted,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                provider.syncConfig?.enabled == true ? '已配置' : '未配置',
                style: TextStyle(
                  color: provider.syncConfig?.enabled == true 
                      ? AppColors.success 
                      : AppColors.muted,
                ),
              ),
            ],
          ),
          if (lastSync != null) ...[
            const SizedBox(height: 8),
            Text(
              '最后同步: ${_formatDateTime(lastSync)}',
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            provider.syncStatusMessage ?? '',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncResult() {
    final isCertError = _syncResultMessage?.contains('证书') == true ||
        _syncResultMessage?.contains('CERT') == true ||
        _syncResultMessage?.contains('certificate') == true ||
        _syncResultMessage?.contains('SSL') == true ||
        _syncResultMessage?.contains('TLS') == true ||
        _syncResultMessage?.contains('ERR_CERT') == true;

    if (isCertError) {
      return _buildCertErrorCard();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _syncResultSuccess 
            ? AppColors.success.withOpacity(0.1)
            : AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _syncResultSuccess 
              ? AppColors.success.withOpacity(0.3)
              : AppColors.error.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _syncResultSuccess ? Icons.check_circle_outline : Icons.error_outline,
            color: _syncResultSuccess ? AppColors.success : AppColors.error,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _syncResultMessage!,
              style: TextStyle(
                color: _syncResultSuccess ? AppColors.success : AppColors.error,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.warning.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.security,
                color: AppColors.warning,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '服务器证书不受信任',
                  style: TextStyle(
                    color: AppColors.warning,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '您连接的 WebDAV 服务器使用了自签名证书，浏览器默认不信任此类证书。',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bg3,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.rule),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🔧 解决步骤：',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _buildSolutionStep('1', '点击下方"打开服务器地址"按钮'),
                _buildSolutionStep('2', '在浏览器弹出的安全警告中，点击"继续访问"或"高级"→"继续前往"'),
                _buildSolutionStep('3', '确认网站可以正常访问后，返回此页面'),
                _buildSolutionStep('4', '重新点击"测试连接"按钮'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openServerUrl(),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('打开服务器地址'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.accent),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSolutionStep(String step, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.accent.withOpacity(0.3)),
            ),
            child: Center(
              child: Text(
                step,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openServerUrl() {
    final url = _serverUrlController.text.trim();
    if (url.isNotEmpty) {
      // 移除末尾的斜杠，确保URL格式正确
      String openUrl = url;
      if (openUrl.endsWith('/')) {
        openUrl = openUrl.substring(0, openUrl.length - 1);
      }
      // 使用 JavaScript 打开新窗口
      _openInNewTab(openUrl);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先输入服务器地址')),
      );
    }
  }

  void _openInNewTab(String url) {
    // 复制 URL 到剪贴板，并提示用户手动打开
    Clipboard.setData(ClipboardData(text: url));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('URL 已复制到剪贴板，请粘贴到浏览器打开: $url'),
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  Widget _buildActionButtons(VaultProvider provider) {
    final isSyncing = provider.isSyncing;
    
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isSyncing ? null : _saveConfig,
            icon: const Icon(Icons.save),
            label: const Text('保存配置'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isSyncing ? null : _testConnection,
                icon: const Icon(Icons.wifi_tethering),
                label: const Text('测试连接'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isSyncing ? null : _syncToCloud,
                icon: isSyncing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.accent,
                        ),
                      )
                    : const Icon(Icons.cloud_upload),
                label: const Text('上传到云端'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: isSyncing ? null : _syncFromCloud,
            icon: const Icon(Icons.cloud_download),
            label: const Text('从云端同步'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showHelpDialog(context),
            icon: const Icon(Icons.help_outline),
            label: const Text('查看帮助'),
          ),
        ),
      ],
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: AppColors.accent),
            SizedBox(width: 8),
            Text('WebDAV 配置帮助'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHelpSection(
                '支持的服务器',
                '• 坚果云 (jianguoyun.com)\n• OwnCloud / Nextcloud\n• 群晖 NAS (Synology)\n• 其他支持 WebDAV 的服务',
              ),
              const SizedBox(height: 16),
              _buildHelpSection(
                '坚果云配置示例',
                '服务器地址: https://dav.jianguyun.com/dav/\n用户名: 您的邮箱\n密码: 应用密码（不是登录密码）',
              ),
              const SizedBox(height: 16),
              _buildHelpSection(
                'Nextcloud配置示例',
                '服务器地址: https://your-domain.com/remote.php/dav/files/用户名/\n用户名: 您的用户名\n密码: 应用密码',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber, color: AppColors.warning, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '注意：部分服务器需要配置 CORS 才能从 Web 浏览器访问',
                        style: TextStyle(color: AppColors.warning, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
