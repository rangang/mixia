import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vault_provider.dart';
import '../models/password_entry.dart';
import '../models/entry_type_config.dart';
import '../theme/app_theme.dart';
import '../widgets/entry_list_item.dart';
import '../widgets/app_logo.dart';
import '../utils/responsive.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Responsive(
      mobile: _buildMobileLayout(),
      desktop: _buildDesktopLayout(),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('密匣'),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock),
            onPressed: () {
              context.read<VaultProvider>().lock();
              Navigator.of(context).pushReplacementNamed('/lock');
            },
            tooltip: '锁定',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            tooltip: '设置',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add_entry'),
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add, color: AppColors.bg),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 240,
      color: AppColors.bg2,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
            child: const AppLogo(size: 50, showText: false),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              '密匣',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
          ),
          const Divider(color: AppColors.rule),
          _buildSidebarItem(Icons.home, '主页', isActive: true, onTap: () {}),
          _buildSidebarItem(Icons.vpn_key, '全部条目', onTap: () => Navigator.pushNamed(
              context, '/entries',
              arguments: {'type': null, 'title': '全部条目'})),
          const Divider(color: AppColors.rule, height: 16),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: EntryType.values.length,
              itemBuilder: (context, index) {
                final type = EntryType.values[index];
                final config = EntryTypes.getConfig(type);
                final count = context.read<VaultProvider>().getEntriesByType(type).length;
                return _buildSidebarItem(
                  config.icon,
                  config.label,
                  onTap: () => Navigator.pushNamed(
                    context, '/entries',
                    arguments: {'type': type, 'title': config.label},
                  ),
                  trailing: count > 0 ? Text(
                    count.toString(),
                    style: const TextStyle(color: AppColors.muted, fontSize: 12),
                  ) : null,
                );
              },
            ),
          ),
          const Divider(color: AppColors.rule),
          _buildSidebarItem(Icons.add, '添加条目', onTap: () => Navigator.pushNamed(context, '/add_entry')),
          _buildSidebarItem(Icons.security, '安全审计', onTap: () => Navigator.pushNamed(context, '/security_audit')),
          _buildSidebarItem(Icons.settings, '设置', onTap: () => Navigator.pushNamed(context, '/settings')),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String title, {bool isActive = false, VoidCallback? onTap, Widget? trailing}) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? AppColors.accent : AppColors.muted,
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? AppColors.accent : AppColors.ink,
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        trailing: trailing,
        onTap: onTap,
        selected: isActive,
        selectedTileColor: AppColors.accent.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<VaultProvider>(
      builder: (context, provider, _) {
        final stats = provider.getStatistics();
        final recentEntries = _searchQuery.isEmpty
            ? provider.getRecentEntries()
            : provider.searchEntries(_searchQuery);

        return Column(
          children: [
            if (Responsive.isDesktop(context))
              Container(
                padding: ResponsivePadding.all(context),
                child: _buildSearchBar(),
              ),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: ResponsivePadding.all(context),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!Responsive.isDesktop(context)) ...[
                            _buildSearchBar(),
                            const SizedBox(height: 24),
                          ],
                          _buildStatistics(stats),
                          const SizedBox(height: 24),
                          _buildCategoryGrid(provider),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _searchQuery.isEmpty ? '最近使用' : '搜索结果',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: AppColors.ink,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pushNamed(
                                    context, '/entries',
                                    arguments: {'type': null, 'title': '全部条目'}),
                                child: const Text('查看全部'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (recentEntries.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final entry = recentEntries[index];
                          return EntryListItem(
                            entry: entry,
                            onTap: () => Navigator.pushNamed(
                                context, '/entry_detail',
                                arguments: entry.id),
                            onDelete: () => provider.deleteEntry(entry.id),
                            onToggleFavorite: () {
                              final updated = entry.copyWith(isFavorite: !entry.isFavorite);
                              provider.updateEntry(updated);
                            },
                          );
                        },
                        childCount: recentEntries.length,
                      ),
                    ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 80),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
      decoration: InputDecoration(
        hintText: '搜索密码条目...',
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
    );
  }

  Widget _buildStatistics(Map<String, int> stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = Responsive.isDesktop(context);
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isDesktop ? 4 : 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: isDesktop ? 2.0 : 1.7,
          children: [
            _buildStatCard(
              icon: Icons.vpn_key,
              label: '总条目',
              value: stats['total'].toString(),
              color: AppColors.accent,
            ),
            _buildStatCard(
              icon: Icons.login,
              label: '登录',
              value: stats['login'].toString(),
              color: EntryTypes.getColor(EntryType.login),
            ),
            _buildStatCard(
              icon: Icons.credit_card,
              label: '银行卡',
              value: stats['card'].toString(),
              color: EntryTypes.getColor(EntryType.card),
            ),
            _buildStatCard(
              icon: Icons.star,
              label: '收藏',
              value: stats['favorite'].toString(),
              color: AppColors.accent2,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final isDesktop = Responsive.isDesktop(context);
    return Container(
      padding: EdgeInsets.all(isDesktop ? 20 : 12),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.rule),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: isDesktop ? 28 : 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: isDesktop ? 24 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: AppColors.muted,
              fontSize: isDesktop ? 13 : 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(VaultProvider provider) {
    final isDesktop = Responsive.isDesktop(context);
    final types = EntryType.values;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 5 : 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: isDesktop ? 1.8 : 2.0,
      ),
      itemCount: types.length,
      itemBuilder: (context, index) {
        final type = types[index];
        final config = EntryTypes.getConfig(type);
        return _buildCategoryCard(
          context: context,
          icon: config.icon,
          title: config.label,
          count: provider.getEntriesByType(type).length,
          color: config.color,
          onTap: () => Navigator.pushNamed(context, '/entries',
              arguments: {'type': type, 'title': config.label}),
        );
      },
    );
  }

  Widget _buildCategoryCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required int count,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDesktop = Responsive.isDesktop(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(isDesktop ? 16 : 12),
        decoration: BoxDecoration(
          color: AppColors.bg2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.rule),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: isDesktop ? 40 : 36,
              height: isDesktop ? 40 : 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: isDesktop ? 22 : 18),
            ),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
                fontSize: isDesktop ? 13 : 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '$count 项',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: isDesktop ? 12 : 11,
              ),
            ),
          ],
        ),
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
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.bg2,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.rule),
              ),
              child: const Icon(
                Icons.lock_open,
                size: 40,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? '密码库为空' : '没有找到匹配的条目',
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
                  ? '点击右下角按钮添加您的第一个密码'
                  : '尝试其他搜索关键词',
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/add_entry'),
                icon: const Icon(Icons.add),
                label: const Text('添加条目'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
