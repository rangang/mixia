import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/password_entry.dart';
import '../models/entry_type_config.dart';
import '../providers/vault_provider.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../utils/secure_clipboard.dart';

class EntryDetailScreen extends StatefulWidget {
  final String entryId;

  const EntryDetailScreen({super.key, required this.entryId});

  @override
  State<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends State<EntryDetailScreen> {
  final Set<String> _revealedFields = {};

  @override
  Widget build(BuildContext context) {
    return Consumer<VaultProvider>(
      builder: (context, provider, _) {
        final entry = provider.getEntry(widget.entryId);

        if (entry == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('条目详情')),
            body: const Center(child: Text('条目不存在')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(entry.title),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Navigator.pushNamed(context, '/edit_entry', arguments: entry);
                },
              ),
              IconButton(
                icon: Icon(
                  entry.isFavorite ? Icons.star : Icons.star_border,
                  color: entry.isFavorite ? AppColors.accent2 : null,
                ),
                onPressed: () {
                  final updated = entry.copyWith(isFavorite: !entry.isFavorite);
                  provider.updateEntry(updated);
                },
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) => _handleMenuAction(context, value, entry),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'copy_all',
                    child: Row(
                      children: [
                        Icon(Icons.copy_all, size: 18),
                        SizedBox(width: 8),
                        Text('复制所有敏感信息'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: AppColors.error, size: 18),
                        SizedBox(width: 8),
                        Text('删除', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Responsive(
            mobile: _buildMobileLayout(entry),
            desktop: _buildDesktopLayout(entry),
          ),
        );
      },
    );
  }

  Widget _buildMobileLayout(PasswordEntry entry) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeader(entry),
        const SizedBox(height: 24),
        ..._buildFieldsList(entry),
        const SizedBox(height: 24),
        _buildMetadata(entry),
        const SizedBox(height: 32),
        _buildActionButtons(context, entry),
      ],
    );
  }

  Widget _buildDesktopLayout(PasswordEntry entry) {
    final fieldConfigs = entry.fieldConfigs;
    final halfLength = (fieldConfigs.length / 2).ceil();

    return Center(
      child: SizedBox(
        width: 900,
        child: ListView(
          padding: ResponsivePadding.all(context),
          children: [
            _buildHeader(entry),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: _buildFieldsWidgets(entry, fieldConfigs.sublist(0, halfLength)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: _buildFieldsWidgets(entry, fieldConfigs.sublist(halfLength)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildMetadata(entry),
            const SizedBox(height: 32),
            _buildActionButtons(context, entry),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFieldsList(PasswordEntry entry) {
    return _buildFieldsWidgets(entry, entry.fieldConfigs);
  }

  List<Widget> _buildFieldsWidgets(PasswordEntry entry, List<EntryFieldConfig> fields) {
    final widgets = <Widget>[];
    for (var i = 0; i < fields.length; i++) {
      final field = fields[i];
      if (field.key == 'title') continue;
      final value = entry.getField(field.key);
      if (value.isEmpty) continue;
      widgets.add(_buildFieldWidget(context, entry, field, value));
      if (i < fields.length - 1) {
        widgets.add(const SizedBox(height: 12));
      }
    }
    return widgets;
  }

  Widget _buildHeader(PasswordEntry entry) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.rule),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: entry.typeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(entry.icon, color: entry.typeColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: entry.typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    entry.typeLabel,
                    style: TextStyle(
                      color: entry.typeColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (entry.displaySubtitle.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    entry.displaySubtitle,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldWidget(BuildContext context, PasswordEntry entry, EntryFieldConfig field, String value) {
    if (value.isEmpty) return const SizedBox.shrink();

    final isSensitive = field.isSensitive;
    final isRevealed = _revealedFields.contains(field.key);
    final displayValue = isSensitive && !isRevealed ? '••••••••••••' : value;
    final isMultiline = field.fieldType == EntryFieldType.multiline;
    final isLink = field.fieldType == EntryFieldType.url;

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
          Row(
            children: [
              Icon(field.icon, size: 16, color: AppColors.muted),
              const SizedBox(width: 8),
              Text(
                field.label,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (isSensitive)
                InkWell(
                  onTap: () {
                    setState(() {
                      if (isRevealed) {
                        _revealedFields.remove(field.key);
                      } else {
                        _revealedFields.add(field.key);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      isRevealed ? Icons.visibility_off : Icons.visibility,
                      size: 16,
                      color: AppColors.muted,
                    ),
                  ),
                ),
              if (isSensitive) const SizedBox(width: 4),
              InkWell(
                onTap: () {
                  SecureClipboard.copy(value);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${field.label} 已复制到剪贴板')),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: const Icon(
                    Icons.copy,
                    size: 16,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            displayValue,
            style: TextStyle(
              fontFamily: isSensitive ? 'JetBrainsMono' : null,
              color: isLink ? AppColors.accent : AppColors.ink,
              fontSize: 15,
              height: isMultiline ? 1.5 : 1.0,
              letterSpacing: isSensitive && !isRevealed ? 2 : 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadata(PasswordEntry entry) {
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
            '元数据',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          _buildMetadataRow('创建时间', _formatDateTime(entry.createdAt)),
          const SizedBox(height: 8),
          _buildMetadataRow('更新时间', _formatDateTime(entry.updatedAt)),
          if (entry.tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildMetadataRow('标签', entry.tags.join(', ')),
          ],
        ],
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, PasswordEntry entry) {
    return Column(
      children: [
        Row(
          children: [
            if (_getPrimaryCopyField(entry) != null)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    final field = _getPrimaryCopyField(entry)!;
                    final value = entry.getField(field.key);
                    SecureClipboard.copy(value);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${field.label} 已复制')),
                    );
                  },
                  icon: Icon(_getPrimaryCopyField(entry)!.icon),
                  label: Text('复制${_getPrimaryCopyField(entry)!.label}'),
                ),
              ),
            if (_getPrimaryCopyField(entry) != null && _hasSensitiveField(entry))
              const SizedBox(width: 12),
            if (_hasSensitiveField(entry))
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final field = _getSensitiveField(entry)!;
                    final value = entry.getField(field.key);
                    SecureClipboard.copy(value);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${field.label} 已复制')),
                    );
                  },
                  icon: Icon(_getSensitiveField(entry)!.icon),
                  label: Text('复制${_getSensitiveField(entry)!.label}'),
                ),
              ),
          ],
        ),
      ],
    );
  }

  EntryFieldConfig? _getPrimaryCopyField(PasswordEntry entry) {
    for (final field in entry.fieldConfigs) {
      if (field.showInList && !field.isSensitive) {
        final value = entry.getField(field.key);
        if (value.isNotEmpty) return field;
      }
    }
    final username = entry.getField('username');
    if (username.isNotEmpty) {
      return entry.fieldConfigs.firstWhere((f) => f.key == 'username', orElse: () => entry.fieldConfigs.first);
    }
    return null;
  }

  EntryFieldConfig? _getSensitiveField(PasswordEntry entry) {
    for (final field in entry.fieldConfigs) {
      if (field.isSensitive) {
        final value = entry.getField(field.key);
        if (value.isNotEmpty) return field;
      }
    }
    return null;
  }

  bool _hasSensitiveField(PasswordEntry entry) {
    return _getSensitiveField(entry) != null;
  }

  void _handleMenuAction(BuildContext context, String action, PasswordEntry entry) {
    if (action == 'delete') {
      _showDeleteConfirmation(context, entry);
    } else if (action == 'copy_all') {
      final buffer = StringBuffer();
      buffer.writeln('【${entry.typeLabel}】${entry.title}');
      buffer.writeln('');
      for (final field in entry.fieldConfigs) {
        final value = entry.getField(field.key);
        if (value.isNotEmpty && field.key != 'notes') {
          buffer.writeln('${field.label}: $value');
        }
      }
      SecureClipboard.copy(buffer.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('条目信息已复制到剪贴板')),
      );
    }
  }

  void _showDeleteConfirmation(BuildContext context, PasswordEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除 "${entry.title}" 吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<VaultProvider>().deleteEntry(entry.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
