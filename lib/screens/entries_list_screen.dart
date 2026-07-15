import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/password_entry.dart';
import '../providers/vault_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/entry_list_item.dart';

class EntriesListScreen extends StatefulWidget {
  final EntryType? type;
  final String title;

  const EntriesListScreen({
    super.key,
    this.type,
    required this.title,
  });

  @override
  State<EntriesListScreen> createState() => _EntriesListScreenState();
}

class _EntriesListScreenState extends State<EntriesListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Consumer<VaultProvider>(
        builder: (context, provider, _) {
          List<PasswordEntry> entries;
          if (widget.type != null) {
            entries = provider.getEntriesByType(widget.type!);
          } else {
            entries = provider.vault.entries;
          }

          if (_searchQuery.isNotEmpty) {
            entries = entries.where((e) {
              final query = _searchQuery.toLowerCase();
              if (e.title.toLowerCase().contains(query)) return true;
              for (final field in e.fieldConfigs) {
                final value = e.getField(field.key);
                if (value.toLowerCase().contains(query)) return true;
              }
              return false;
            }).toList();
          }

          entries.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: '搜索...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.muted),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: AppColors.muted),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                  ),
                ),
              ),
              Expanded(
                child: entries.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        itemCount: entries.length,
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          return EntryListItem(
                            entry: entry,
                            onTap: () => Navigator.pushNamed(
                              context,
                              '/entry_detail',
                              arguments: entry.id,
                            ),
                            onDelete: () => provider.deleteEntry(entry.id),
                            onToggleFavorite: () {
                              final updated = entry.copyWith(isFavorite: !entry.isFavorite);
                              provider.updateEntry(updated);
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/add_entry'),
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.add, color: AppColors.bg),
        label: const Text('添加条目', style: TextStyle(color: AppColors.bg)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.bg2,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.rule),
              ),
              child: const Icon(
                Icons.search_off,
                size: 32,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? '暂无条目' : '没有找到匹配的条目',
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? '点击右下角按钮添加'
                  : '尝试其他搜索关键词',
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
