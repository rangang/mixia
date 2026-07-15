import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vault_provider.dart';
import '../theme/app_theme.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _hasAutoPrompted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoPromptBiometric();
    });
  }

  void _autoPromptBiometric() {
    if (_hasAutoPrompted) return;
    final provider = context.read<VaultProvider>();
    if (provider.biometricAvailable && provider.biometricEnabled && !provider.isLoading) {
      _hasAutoPrompted = true;
      _biometricUnlock();
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<VaultProvider>();
    final success = await provider.unlock(_passwordController.text);

    if (mounted && success) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  Future<void> _biometricUnlock() async {
    final provider = context.read<VaultProvider>();
    
    final success = await provider.unlockWithBiometrics();

    if (mounted && success) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.5),
            radius: 1.5,
            colors: [
              AppColors.accent.withOpacity(0.08),
              AppColors.bg.withOpacity(0),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.accent.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.fingerprint,
                        size: 40,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '密匣已锁定',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '验证身份以解锁密码库',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.muted,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      autofocus: true,
                      onFieldSubmitted: (_) => _unlock(),
                      decoration: InputDecoration(
                        labelText: '主密码',
                        hintText: '输入主密码解锁',
                        prefixIcon: const Icon(Icons.key, color: AppColors.muted),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: AppColors.muted,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入主密码';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Consumer<VaultProvider>(
                      builder: (context, provider, _) {
                        if (provider.errorMessage != null) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.error.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: AppColors.error, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    provider.errorMessage!,
                                    style: const TextStyle(
                                        color: AppColors.error, fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: Consumer<VaultProvider>(
                        builder: (context, provider, _) {
                          return ElevatedButton.icon(
                            onPressed: provider.isLoading ? null : _unlock,
                            icon: provider.isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.bg,
                                    ),
                                  )
                                : const Icon(Icons.lock_open),
                            label: Text(provider.isLoading ? '解锁中...' : '解锁'),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Consumer<VaultProvider>(
                      builder: (context, provider, _) {
                        if (provider.biometricAvailable && provider.biometricEnabled) {
                          return Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: provider.isLoading ? null : _biometricUnlock,
                                  icon: const Icon(Icons.fingerprint),
                                  label: const Text('使用生物识别解锁'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.accent,
                                    side: const BorderSide(color: AppColors.accent),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          );
                        }
                        return const SizedBox(height: 24);
                      },
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.bg2,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.rule),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.security, color: AppColors.accent3, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '数据采用端到端加密，仅您可访问',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
