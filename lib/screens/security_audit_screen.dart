import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/password_entry.dart';
import '../providers/vault_provider.dart';
import '../theme/app_theme.dart';
import '../utils/password_generator.dart';

class SecurityAuditScreen extends StatefulWidget {
  const SecurityAuditScreen({super.key});

  @override
  State<SecurityAuditScreen> createState() => _SecurityAuditScreenState();
}

class _SecurityAuditScreenState extends State<SecurityAuditScreen> {
  bool _isAnalyzing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('安全审计'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
            },
          ),
        ],
      ),
      body: Consumer<VaultProvider>(
        builder: (context, provider, _) {
          final entries = provider.vault.entries;
          final auditResult = _analyzeEntries(entries);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSecurityScore(auditResult),
              const SizedBox(height: 24),
              _buildAuditStats(auditResult),
              const SizedBox(height: 24),
              if (auditResult['weakPasswords'].isNotEmpty) ...[
                _buildIssueSection(
                  title: '弱密码',
                  icon: Icons.warning,
                  color: AppColors.error,
                  entries: auditResult['weakPasswords'] as List<PasswordEntry>,
                  description: '这些密码强度不足，建议立即更换',
                ),
                const SizedBox(height: 16),
              ],
              if (auditResult['duplicatePasswords'].isNotEmpty) ...[
                _buildIssueSection(
                  title: '重复密码',
                  icon: Icons.content_copy,
                  color: AppColors.warning,
                  entries:
                      auditResult['duplicatePasswords'] as List<PasswordEntry>,
                  description: '多个账户使用相同密码，存在安全风险',
                ),
                const SizedBox(height: 16),
              ],
              if (auditResult['oldPasswords'].isNotEmpty) ...[
                _buildIssueSection(
                  title: '长期未修改',
                  icon: Icons.schedule,
                  color: AppColors.accent2,
                  entries: auditResult['oldPasswords'] as List<PasswordEntry>,
                  description: '超过90天未修改的密码',
                ),
                const SizedBox(height: 16),
              ],
              if (auditResult['weakPasswords'].isEmpty &&
                  auditResult['duplicatePasswords'].isEmpty &&
                  auditResult['oldPasswords'].isEmpty)
                _buildAllGoodState(),
            ],
          );
        },
      ),
    );
  }

  Map<String, dynamic> _analyzeEntries(List<PasswordEntry> entries) {
    final weakPasswords = <PasswordEntry>[];
    final duplicatePasswords = <PasswordEntry>[];
    final oldPasswords = <PasswordEntry>[];
    final passwordMap = <String, List<PasswordEntry>>{};

    for (final entry in entries) {
      if (entry.password.isNotEmpty) {
        final strength = PasswordGenerator.calculateStrength(entry.password);
        if (strength < 0.5) {
          weakPasswords.add(entry);
        }

        passwordMap.putIfAbsent(entry.password, () => []).add(entry);

        final daysSinceUpdate = DateTime.now()
            .difference(entry.updatedAt)
            .inDays;
        if (daysSinceUpdate > 90) {
          oldPasswords.add(entry);
        }
      }
    }

    for (final entriesWithSamePassword in passwordMap.values) {
      if (entriesWithSamePassword.length > 1) {
        duplicatePasswords.addAll(entriesWithSamePassword);
      }
    }

    final totalIssues =
        weakPasswords.length + duplicatePasswords.length + oldPasswords.length;

    int score = 100;
    score -= weakPasswords.length * 10;
    score -= duplicatePasswords.length * 5;
    score -= oldPasswords.length * 3;
    score = score.clamp(0, 100);

    return {
      'score': score,
      'totalEntries': entries.length,
      'weakPasswords': weakPasswords,
      'duplicatePasswords': duplicatePasswords,
      'oldPasswords': oldPasswords,
      'totalIssues': totalIssues,
    };
  }

  Widget _buildSecurityScore(Map<String, dynamic> auditResult) {
    final score = auditResult['score'] as int;
    Color scoreColor;
    String scoreLabel;

    if (score >= 80) {
      scoreColor = AppColors.success;
      scoreLabel = '良好';
    } else if (score >= 60) {
      scoreColor = AppColors.accent2;
      scoreLabel = '一般';
    } else if (score >= 40) {
      scoreColor = AppColors.warning;
      scoreLabel = '较弱';
    } else {
      scoreColor = AppColors.error;
      scoreLabel = '危险';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: score / 100,
                        strokeWidth: 8,
                        backgroundColor: context.appBorder,
                        valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                      ),
                    ),
                    Center(
                      child: Text(
                        '$score',
                        style: TextStyle(
                          color: scoreColor,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '安全评分',
                      style: TextStyle(
                        color: context.appMutedText,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      scoreLabel,
                      style: TextStyle(
                        color: scoreColor,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '共审计 ${auditResult['totalEntries']} 个条目',
                      style: TextStyle(
                        color: context.appMutedText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAuditStats(Map<String, dynamic> auditResult) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            label: '弱密码',
            value: (auditResult['weakPasswords'] as List).length,
            color: AppColors.error,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            label: '重复密码',
            value: (auditResult['duplicatePasswords'] as List).length,
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            label: '过期密码',
            value: (auditResult['oldPasswords'] as List).length,
            color: AppColors.accent2,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required int value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: context.appMutedText, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildIssueSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<PasswordEntry> entries,
    required String description,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        description,
                        style: TextStyle(
                          color: context.appMutedText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${entries.length}',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: context.appBorder),
          ...entries
              .take(3)
              .map(
                (entry) => ListTile(
                  dense: true,
                  leading: Icon(
                    Icons.lock_outline,
                    size: 18,
                    color: context.appMutedText,
                  ),
                  title: Text(
                    entry.title,
                    style: TextStyle(color: context.appText, fontSize: 14),
                  ),
                  subtitle: Text(
                    entry.username.isNotEmpty ? entry.username : '无用户名',
                    style: TextStyle(color: context.appMutedText, fontSize: 12),
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.edit,
                      size: 18,
                      color: AppColors.accent,
                    ),
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/edit_entry',
                        arguments: entry,
                      );
                    },
                  ),
                ),
              ),
          if (entries.length > 3)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                '还有 ${entries.length - 3} 个条目...',
                style: TextStyle(color: context.appMutedText, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAllGoodState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 64,
            color: AppColors.success,
          ),
          const SizedBox(height: 16),
          Text(
            '太棒了！',
            style: TextStyle(
              color: context.appText,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '您的密码库目前没有发现安全问题',
            style: TextStyle(color: context.appMutedText, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
