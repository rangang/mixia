import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/password_entry.dart';
import '../providers/vault_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/entry_list_item.dart';
import '../widgets/ios_surface.dart';

class EntriesListScreen extends StatefulWidget {
  final EntryType? type;
  final String title;

  const EntriesListScreen({super.key, this.type, required this.title});

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
      appBar: AppBar(title: Text(widget.title)),
      body: IosBackdrop(
        child: Consumer<VaultProvider>(
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
                      hintText: '搜索标题、账号或备注',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              tooltip: '清除搜索',
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${entries.length} 个条目',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
                Expanded(
                  child: entries.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 96),
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
                                final updated = entry.copyWith(
                                  isFavorite: !entry.isFavorite,
                                );
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/add_entry'),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.onAccent,
        extendedIconLabelSpacing: 8,
        extendedPadding: const EdgeInsetsDirectional.fromSTEB(18, 0, 22, 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          '添加条目',
          maxLines: 1,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final colors = Theme.of(context).colorScheme;
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
                color: colors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Icon(
                Icons.search_off,
                size: 32,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? '暂无条目' : '没有找到匹配的条目',
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty ? '点击右下角按钮添加' : '尝试其他搜索关键词',
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
