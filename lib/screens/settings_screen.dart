import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../providers/vault_provider.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isSyncing = false;
  String? _syncMessage;
  bool _syncSuccess = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: Consumer<VaultProvider>(
        builder: (context, provider, _) {
          if (Responsive.isDesktop(context)) {
            return Center(
              child: SizedBox(
                width: 800,
                child: ListView(
                  padding: ResponsivePadding.all(context),
                  children: _buildSettingsList(context, provider),
                ),
              ),
            );
          }
          return ListView(
            padding: ResponsivePadding.all(context),
            children: _buildSettingsList(context, provider),
          );
        },
      ),
    );
  }

  List<Widget> _buildSettingsList(BuildContext context, VaultProvider provider) {
    return [
      _buildSectionHeader('安全'),
      _buildSettingTile(
        icon: Icons.lock_outline,
        title: '锁定密码库',
        subtitle: '立即锁定，需要主密码解锁',
        onTap: () {
          provider.lock();
          Navigator.pushReplacementNamed(context, '/lock');
        },
      ),
      _buildSettingTile(
        icon: Icons.timer_outlined,
        title: '自动锁定',
        subtitle: '5分钟无操作后自动锁定',
        trailing: Switch(
          value: true,
          onChanged: (value) {},
          activeColor: AppColors.accent,
        ),
      ),
      Consumer<VaultProvider>(
        builder: (context, provider, _) {
          if (provider.biometricAvailable) {
            return _buildSettingTile(
              icon: Icons.fingerprint,
              title: '生物识别解锁',
              subtitle: provider.biometricEnabled 
                  ? '已启用 Touch ID/Face ID' 
                  : '使用指纹或面容快速解锁',
              trailing: Switch(
                value: provider.biometricEnabled,
                onChanged: provider.isAuthenticated
                    ? (value) => provider.setBiometricEnabled(value)
                    : null,
                activeColor: AppColors.accent,
              ),
            );
          }
          return _buildSettingTile(
            icon: Icons.fingerprint,
            title: '生物识别解锁',
            subtitle: '此设备不支持生物识别',
            onTap: null,
          );
        },
      ),
      _buildSettingTile(
        icon: Icons.security,
        title: '安全审计',
        subtitle: '检查密码强度和重复',
        onTap: () => _showFeatureNotReady(context, '安全审计'),
      ),
      const SizedBox(height: 24),
      _buildSectionHeader('同步'),
      _buildSettingTile(
        icon: Icons.sync,
        title: '同步设置',
        subtitle: '配置WebDAV/SFTP同步',
        onTap: () => Navigator.pushNamed(context, '/sync_settings'),
      ),
      _buildSettingTile(
        icon: Icons.cloud_sync_outlined,
        title: '立即同步',
        subtitle: provider.syncConfig?.enabled == true 
            ? (provider.isSyncing ? '同步中...' : '上次同步: ${_formatLastSync(provider.syncConfig?.lastSyncTime)}')
            : '请先在同步设置中配置并启用',
        onTap: provider.syncConfig?.enabled == true && !provider.isSyncing
            ? () => _showSyncDialog(context, provider)
            : null,
      ),
      if (_syncMessage != null) _buildSyncResultCard(),
      const SizedBox(height: 24),
      _buildSectionHeader('数据'),
      _buildSettingTile(
        icon: Icons.file_download_outlined,
        title: '导出密码库',
        subtitle: '导出加密JSON备份到剪贴板和文件',
        onTap: () => _exportVault(context, provider),
      ),
      _buildSettingTile(
        icon: Icons.file_upload_outlined,
        title: '导入密码库',
        subtitle: '从备份JSON恢复密码库',
        onTap: () => _showImportDialog(context, provider),
      ),
      const SizedBox(height: 24),
      _buildSectionHeader('外观'),
      _buildSettingTile(
        icon: Icons.dark_mode_outlined,
        title: '深色模式',
        subtitle: '切换应用主题',
        trailing: Switch(
          value: provider.isDarkMode,
          onChanged: (value) {
            provider.setDarkMode(value);
          },
          activeColor: AppColors.accent,
        ),
      ),
      const SizedBox(height: 24),
      _buildSectionHeader('关于'),
      _buildSettingTile(
        icon: Icons.info_outline,
        title: '关于密匣',
        subtitle: '版本 1.0.0',
        onTap: () => _showAboutDialog(context),
      ),
      _buildSettingTile(
        icon: Icons.help_outline,
        title: '帮助与支持',
        subtitle: '使用指南和常见问题',
        onTap: () => _showHelpDialog(context),
      ),
      const SizedBox(height: 32),
      _buildSettingTile(
        icon: Icons.logout,
        title: '重置密码库',
        subtitle: '清除所有数据并重新设置',
        textColor: AppColors.error,
        iconColor: AppColors.error,
        onTap: () => _showResetConfirmation(context, provider),
      ),
      const SizedBox(height: 24),
    ];
  }

  Widget _buildSyncResultCard() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _syncSuccess 
            ? AppColors.success.withOpacity(0.1)
            : AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _syncSuccess 
              ? AppColors.success.withOpacity(0.3)
              : AppColors.error.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _syncSuccess ? Icons.check_circle : Icons.error_outline,
            color: _syncSuccess ? AppColors.success : AppColors.error,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _syncMessage!,
              style: TextStyle(
                color: _syncSuccess ? AppColors.success : AppColors.error,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatLastSync(DateTime? time) {
    if (time == null) return '从未同步';
    return '${time.month}/${time.day} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _showSyncDialog(BuildContext context, VaultProvider provider) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cloud_sync, color: AppColors.accent),
            SizedBox(width: 8),
            Text('立即同步'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('请选择同步方向：'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.cloud_upload),
                label: const Text('上传到云端（备份本地数据）'),
                onPressed: () async {
                  Navigator.pop(context);
                  await _performSync(context, provider, isUpload: true);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.cloud_download),
                label: const Text('从云端同步（恢复云端数据）'),
                onPressed: () async {
                  Navigator.pop(context);
                  await _performSync(context, provider, isUpload: false);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  Future<void> _performSync(BuildContext context, VaultProvider provider, {required bool isUpload}) async {
    setState(() {
      _isSyncing = true;
      _syncMessage = isUpload ? '正在上传到云端...' : '正在从云端同步...';
      _syncSuccess = false;
    });

    try {
      final result = isUpload 
          ? await provider.syncToCloud() 
          : await provider.syncFromCloud();
      
      setState(() {
        _isSyncing = false;
        _syncMessage = result.success 
            ? (isUpload ? '上传成功！数据已备份到云端' : '同步成功！已从云端恢复数据')
            : result.errorMessage ?? '同步失败';
        _syncSuccess = result.success;
      });
    } catch (e) {
      setState(() {
        _isSyncing = false;
        _syncMessage = '同步错误: $e';
        _syncSuccess = false;
      });
    }
  }

  Future<void> _exportVault(BuildContext context, VaultProvider provider) async {
    try {
      final json = await provider.exportVault();
      
      await Clipboard.setData(ClipboardData(text: json));
      
      String? filePath;
      if (!kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
        try {
          final dir = await getApplicationDocumentsDirectory();
          final fileName = 'mi_xia_backup_${DateTime.now().millisecondsSinceEpoch}.json';
          final file = File('${dir.path}/$fileName');
          await file.writeAsString(json);
          filePath = file.path;
        } catch (e) {
          debugPrint('Failed to save file: $e');
        }
      }
      
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success),
                SizedBox(width: 8),
                Text('导出成功'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('密码库已加密导出：'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.bg3,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check, color: AppColors.success, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '已复制到剪贴板',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                if (filePath != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.bg3,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.folder, color: AppColors.accent, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '已保存到: $filePath',
                            style: const TextStyle(fontSize: 11, color: AppColors.muted),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                          '备份文件包含加密数据，请妥善保管，不要分享给他人',
                          style: TextStyle(color: AppColors.warning, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('确定'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _showImportDialog(BuildContext context, VaultProvider provider) async {
    final controller = TextEditingController();
    bool isLoading = false;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.file_upload, color: AppColors.accent),
              SizedBox(width: 8),
              Text('导入密码库'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('请粘贴之前导出的加密备份JSON内容：'),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText: '在此粘贴备份内容...',
                    border: const OutlineInputBorder(),
                    errorText: errorMessage,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.paste, size: 18),
                  label: const Text('从剪贴板粘贴'),
                  onPressed: () async {
                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                    if (data?.text != null) {
                      setDialogState(() {
                        controller.text = data!.text!;
                        errorMessage = null;
                      });
                    }
                  },
                ),
                if (isLoading) ...[
                  const SizedBox(height: 16),
                  const Center(child: CircularProgressIndicator()),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (controller.text.trim().isEmpty) {
                  setDialogState(() {
                    errorMessage = '请输入备份内容';
                  });
                  return;
                }
                
                setDialogState(() {
                  isLoading = true;
                  errorMessage = null;
                });

                try {
                  final success = await provider.importVault(controller.text.trim());
                  if (success && context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('导入成功！密码库已恢复'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  } else {
                    setDialogState(() {
                      isLoading = false;
                      errorMessage = '导入失败：无效的备份数据';
                    });
                  }
                } catch (e) {
                  setDialogState(() {
                    isLoading = false;
                    errorMessage = '导入错误: $e';
                  });
                }
              },
              child: const Text('导入'),
            ),
          ],
        ),
      ),
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
            Text('帮助与支持'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHelpSection(
                '快速开始',
                '1. 首次使用请设置主密码，这是解锁密码库的唯一密钥\n'
                '2. 点击右下角"+"按钮添加密码条目\n'
                '3. 可以按类别（网站、应用、银行卡、安全笔记）组织密码',
              ),
              const SizedBox(height: 16),
              _buildHelpSection(
                '主密码说明',
                '• 主密码是您密码库的唯一密钥，丢失后无法恢复\n'
                '• 请使用强密码并妥善记忆\n'
                '• 应用使用AES-256-GCM加密所有数据',
              ),
              const SizedBox(height: 16),
              _buildHelpSection(
                'WebDAV同步',
                '• 支持坚果云、Nextcloud、群晖NAS等\n'
                '• 数据在上传前已在本地加密，云端只存储密文\n'
                '• 坚果云需要使用"第三方应用密码"而非登录密码\n'
                '• macOS桌面端可以直接连接自签名HTTPS服务器',
              ),
              const SizedBox(height: 16),
              _buildHelpSection(
                '数据备份',
                '• 建议定期导出备份文件\n'
                '• 备份文件是加密的JSON格式\n'
                '• 可以将备份文件存储在安全的位置',
              ),
              const SizedBox(height: 16),
              _buildHelpSection(
                '常见问题',
                'Q: 忘记主密码怎么办？\n'
                'A: 主密码无法找回，只能重置密码库（所有数据将丢失）\n\n'
                'Q: WebDAV连接失败？\n'
                'A: 请检查服务器地址、用户名密码、网络连接，以及CORS/证书设置',
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
        const SizedBox(height: 6),
        Text(
          content,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 12,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  void _showFeatureNotReady(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature功能开发中')),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.muted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? AppColors.accent),
        title: Text(
          title,
          style: TextStyle(color: textColor ?? AppColors.ink),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(
                  color: AppColors.muted.withOpacity(0.8),
                  fontSize: 12,
                ),
              )
            : null,
        trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right, color: AppColors.muted) : null),
        onTap: onTap,
        enabled: onTap != null,
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.security, color: AppColors.accent),
            SizedBox(width: 8),
            Text('密匣'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('零后端存储 · 生物识别认证 · 私有云同步'),
            SizedBox(height: 16),
            Text('版本: 1.0.0'),
            Text('技术栈: Flutter'),
            Text('加密: AES-256-GCM'),
            SizedBox(height: 16),
            Text(
              '密匣是零后端、零信任的跨平台密码管理方案。您的数据完全由本地端加密后存储在个人NAS或云盘中。',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
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

  void _showResetConfirmation(BuildContext context, VaultProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置密码库'),
        content: const Text(
          '此操作将清除所有密码条目和设置，且不可恢复。确定要继续吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await provider.clearAllData();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/setup');
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('重置'),
          ),
        ],
      ),
    );
  }
}
