import 'package:flutter/material.dart';
import '../models/password_entry.dart';
import '../models/entry_type_config.dart';
import '../theme/app_theme.dart';
import '../utils/secure_clipboard.dart';

class EntryListItem extends StatelessWidget {
  final PasswordEntry entry;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleFavorite;

  const EntryListItem({
    super.key,
    required this.entry,
    required this.onTap,
    this.onDelete,
    this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('确认删除'),
            content: Text('确定要删除 "${entry.title}" 吗？此操作不可撤销。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('删除'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        onDelete?.call();
      },
      child: Material(
        color: AppColors.bg2.withOpacity(0.92),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              height: 48,
              child: Row(
                children: [
                  _buildLeading(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.title,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          entry.displaySubtitle,
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _buildTrailing(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeading() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: entry.typeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(entry.icon, color: entry.typeColor, size: 18),
    );
  }

  Widget _buildTrailing(BuildContext context) {
    return SizedBox(
      width: 56,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (entry.isFavorite)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(Icons.star, color: AppColors.accent2, size: 14),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.muted, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onSelected: (value) => _handleMenuAction(context, value),
            itemBuilder: (context) => _buildMenuItems(),
          ),
        ],
      ),
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems() {
    final items = <PopupMenuEntry<String>>[];
    
    final primaryField = _getPrimaryCopyField();
    if (primaryField != null) {
      items.add(PopupMenuItem(
        value: 'copy_primary',
        child: Row(
          children: [
            Icon(primaryField.icon, size: 18),
            const SizedBox(width: 8),
            Text('复制${primaryField.label}'),
          ],
        ),
      ));
    }
    
    final sensitiveField = _getSensitiveField();
    if (sensitiveField != null) {
      items.add(PopupMenuItem(
        value: 'copy_sensitive',
        child: Row(
          children: [
            Icon(sensitiveField.icon, size: 18),
            const SizedBox(width: 8),
            Text('复制${sensitiveField.label}'),
          ],
        ),
      ));
    }
    
    items.add(const PopupMenuItem(
      value: 'copy_all',
      child: Row(
        children: [
          Icon(Icons.copy_all, size: 18),
          SizedBox(width: 8),
          Text('复制所有信息'),
        ],
      ),
    ));
    
    items.add(PopupMenuItem(
      value: 'favorite',
      child: Row(
        children: [
          Icon(
            entry.isFavorite ? Icons.star_border : Icons.star,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(entry.isFavorite ? '取消收藏' : '收藏'),
        ],
      ),
    ));
    
    items.add(const PopupMenuItem(
      value: 'delete',
      child: Row(
        children: [
          Icon(Icons.delete, size: 18, color: AppColors.error),
          SizedBox(width: 8),
          Text('删除', style: TextStyle(color: AppColors.error)),
        ],
      ),
    ));
    
    return items;
  }

  EntryFieldConfig? _getPrimaryCopyField() {
    for (final field in entry.fieldConfigs) {
      if (field.showInList && !field.isSensitive) {
        final value = entry.getField(field.key);
        if (value.isNotEmpty) return field;
      }
    }
    for (final field in entry.fieldConfigs) {
      if (!field.isSensitive && field.key != 'title' && field.key != 'notes') {
        final value = entry.getField(field.key);
        if (value.isNotEmpty) return field;
      }
    }
    return null;
  }

  EntryFieldConfig? _getSensitiveField() {
    for (final field in entry.fieldConfigs) {
      if (field.isSensitive) {
        final value = entry.getField(field.key);
        if (value.isNotEmpty) return field;
      }
    }
    return null;
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'copy_primary':
        final field = _getPrimaryCopyField();
        if (field != null) {
          final value = entry.getField(field.key);
          SecureClipboard.copy(value);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${field.label}已复制，30 秒后自动清除')),
          );
        }
        break;
      case 'copy_sensitive':
        final field = _getSensitiveField();
        if (field != null) {
          final value = entry.getField(field.key);
          SecureClipboard.copy(value);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${field.label}已复制，30 秒后自动清除')),
          );
        }
        break;
      case 'copy_all':
        final buffer = StringBuffer();
        buffer.writeln('【${entry.typeLabel}】${entry.title}');
        buffer.writeln('');
        for (final field in entry.fieldConfigs) {
          final value = entry.getField(field.key);
          if (value.isNotEmpty && field.key != 'notes') {
            buffer.writeln('${field.label}: $value');
          }
        }
        final notes = entry.getField('notes');
        if (notes.isNotEmpty) {
          buffer.writeln('');
          buffer.writeln('备注: $notes');
        }
        SecureClipboard.copy(buffer.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('条目信息已复制，30 秒后自动清除')),
        );
        break;
      case 'favorite':
        onToggleFavorite?.call();
        break;
      case 'delete':
        _showDeleteConfirmation(context);
        break;
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
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
              onDelete?.call();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
