import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vault_provider.dart';
import '../models/password_entry.dart';
import '../models/entry_type_config.dart';
import '../theme/app_theme.dart';
import '../widgets/entry_list_item.dart';
import '../widgets/app_logo.dart';
import '../utils/responsive.dart';
import '../widgets/ios_surface.dart';

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
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shield_rounded, color: AppColors.accent, size: 21),
            SizedBox(width: 8),
            Text('密匣'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.lock),
            onPressed: () {
              context.read<VaultProvider>().lock();
              Navigator.of(context).pushReplacementNamed('/lock');
            },
            tooltip: '锁定',
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            tooltip: '设置',
          ),
        ],
      ),
      body: IosBackdrop(child: _buildBody()),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add_entry'),
        child: const Icon(CupertinoIcons.add),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(child: IosBackdrop(child: _buildBody())),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    final colors = Theme.of(context).colorScheme;
    return GlassSurface(
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.zero,
      child: SizedBox(
        width: 264,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
              child: const AppLogo(size: 50, showText: false),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                '密匣',
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
            ),
            const Divider(),
            _buildSidebarItem(Icons.home, '主页', isActive: true, onTap: () {}),
            _buildSidebarItem(
              Icons.vpn_key,
              '全部条目',
              onTap: () => Navigator.pushNamed(
                context,
                '/entries',
                arguments: {'type': null, 'title': '全部条目'},
              ),
            ),
            const Divider(height: 16),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: EntryType.values.length,
                itemBuilder: (context, index) {
                  final type = EntryType.values[index];
                  final config = EntryTypes.getConfig(type);
                  final count = context
                      .read<VaultProvider>()
                      .getEntriesByType(type)
                      .length;
                  return _buildSidebarItem(
                    config.icon,
                    config.label,
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/entries',
                      arguments: {'type': type, 'title': config.label},
                    ),
                    trailing: count > 0
                        ? Text(
                            count.toString(),
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          )
                        : null,
                  );
                },
              ),
            ),
            const Divider(),
            _buildSidebarItem(
              Icons.add,
              '添加条目',
              onTap: () => Navigator.pushNamed(context, '/add_entry'),
            ),
            _buildSidebarItem(
              Icons.security,
              '安全审计',
              onTap: () => Navigator.pushNamed(context, '/security_audit'),
            ),
            _buildSidebarItem(
              Icons.settings,
              '设置',
              onTap: () => Navigator.pushNamed(context, '/settings'),
            ),
            _buildSidebarItem(
              CupertinoIcons.lock,
              '锁定密码库',
              onTap: () {
                context.read<VaultProvider>().lock();
                Navigator.of(context).pushReplacementNamed('/lock');
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarItem(
    IconData icon,
    String title, {
    bool isActive = false,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? colors.primary : colors.onSurfaceVariant,
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? colors.primary : colors.onSurface,
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        trailing: trailing,
        onTap: onTap,
        selected: isActive,
        selectedTileColor: AppColors.accent.withOpacity(0.12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      ),
    );
  }

  Widget _buildBody() {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: Consumer<VaultProvider>(
          builder: (context, provider, _) {
            final stats = provider.getStatistics();
            final recentEntries = _searchQuery.isEmpty
                ? provider.getRecentEntries()
                : provider.searchEntries(_searchQuery);

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: ResponsivePadding.all(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildVaultHero(stats),
                        const SizedBox(height: 20),
                        _buildSearchBar(),
                        const SizedBox(height: 28),
                        _buildSectionHeader(
                          title: '保险库概览',
                          subtitle: '所有数据均在本地加密保存',
                        ),
                        const SizedBox(height: 14),
                        _buildStatistics(stats),
                        const SizedBox(height: 28),
                        _buildSectionHeader(
                          title: '分类浏览',
                          subtitle: '${stats['total'] ?? 0} 项安全信息',
                        ),
                        const SizedBox(height: 14),
                        _buildCategoryGrid(provider),
                        const SizedBox(height: 26),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildSectionHeader(
                              title: _searchQuery.isEmpty ? '最近使用' : '搜索结果',
                              subtitle: _searchQuery.isEmpty
                                  ? '快速回到常用条目'
                                  : '与关键词匹配的条目',
                            ),
                            TextButton(
                              onPressed: () => Navigator.pushNamed(
                                context,
                                '/entries',
                                arguments: {'type': null, 'title': '全部条目'},
                              ),
                              child: const Text('查看全部 →'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (recentEntries.isEmpty)
                  SliverToBoxAdapter(child: _buildEmptyState())
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final entry = recentEntries[index];
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
                    }, childCount: recentEntries.length),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildVaultHero(Map<String, int> stats) {
    final colors = Theme.of(context).colorScheme;
    final isDesktop = Responsive.isDesktop(context);
    final total = stats['total'] ?? 0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 28 : 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.accent.withOpacity(0.28)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent.withOpacity(0.22),
            AppColors.accent3.withOpacity(0.12),
            colors.surface.withOpacity(0.92),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.10),
            blurRadius: 36,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showArtwork = constraints.maxWidth >= 560;
          return Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppColors.success.withOpacity(0.28),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_user_rounded,
                            color: AppColors.success,
                            size: 15,
                          ),
                          SizedBox(width: 6),
                          Text(
                            '保险库已加密',
                            style: TextStyle(
                              color: AppColors.success,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      '你的数字保险库',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontSize: isDesktop ? 32 : 26,
                            letterSpacing: -0.8,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      total == 0
                          ? '从第一项重要信息开始，建立只属于你的安全空间。'
                          : '$total 项重要信息，已使用 AES-256-GCM 安全守护。',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _buildHeroAction(
                          icon: Icons.password_rounded,
                          label: '生成密码',
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/password_generator',
                          ),
                        ),
                        _buildHeroAction(
                          icon: Icons.health_and_safety_rounded,
                          label: '安全审计',
                          onTap: () =>
                              Navigator.pushNamed(context, '/security_audit'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (showArtwork) ...[
                const SizedBox(width: 32),
                Container(
                  width: 118,
                  height: 118,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent.withOpacity(0.10),
                    border: Border.all(
                      color: AppColors.accent.withOpacity(0.24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.16),
                        blurRadius: 32,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.shield_rounded,
                    color: AppColors.accent,
                    size: 58,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeroAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.onSurface.withOpacity(0.07),
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Semantics(
      textField: true,
      label: '搜索密码库',
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: '搜索标题、账号或备注',
          prefixIcon: const Icon(CupertinoIcons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(CupertinoIcons.clear_circled_solid),
                  tooltip: '清除搜索',
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
        ),
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
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: isDesktop ? 2.15 : 1.4,
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
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(isDesktop ? 20 : 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.22)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.16), colors.surface.withOpacity(0.82)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
              Icon(
                Icons.north_east_rounded,
                color: color.withOpacity(0.55),
                size: 16,
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: isDesktop ? 26 : 22,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: isDesktop ? 13 : 12,
                ),
              ),
            ],
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
        crossAxisCount: isDesktop ? 3 : 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: isDesktop ? 2.8 : 2.05,
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
          onTap: () => Navigator.pushNamed(
            context,
            '/entries',
            arguments: {'type': type, 'title': config.label},
          ),
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
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: '$title，$count 项',
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface.withOpacity(0.78),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(isDesktop ? 16 : 12),
            child: Row(
              children: [
                Container(
                  width: isDesktop ? 46 : 40,
                  height: isDesktop ? 46 : 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: isDesktop ? 22 : 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: isDesktop ? 14 : 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$count 项',
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colors.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ),
          ),
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
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Icon(
                Icons.lock_open,
                size: 40,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? '密码库为空' : '没有找到匹配的条目',
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty ? '点击右下角按钮添加您的第一个密码' : '尝试其他搜索关键词',
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 14),
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
