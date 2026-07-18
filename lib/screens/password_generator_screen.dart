import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/password_generator.dart';
import '../utils/secure_clipboard.dart';

class PasswordGeneratorScreen extends StatefulWidget {
  const PasswordGeneratorScreen({super.key});

  @override
  State<PasswordGeneratorScreen> createState() => _PasswordGeneratorScreenState();
}

class _PasswordGeneratorScreenState extends State<PasswordGeneratorScreen> {
  final _lengthController = TextEditingController(text: '16');
  bool _includeLowercase = true;
  bool _includeUppercase = true;
  bool _includeNumbers = true;
  bool _includeSymbols = true;
  String _generatedPassword = '';
  double _passwordStrength = 0.0;

  @override
  void initState() {
    super.initState();
    _generatePassword();
  }

  @override
  void dispose() {
    _lengthController.dispose();
    super.dispose();
  }

  void _generatePassword() {
    final length = int.tryParse(_lengthController.text) ?? 16;
    setState(() {
      _generatedPassword = PasswordGenerator.generate(
        length: length.clamp(4, 64),
        includeLowercase: _includeLowercase,
        includeUppercase: _includeUppercase,
        includeNumbers: _includeNumbers,
        includeSymbols: _includeSymbols,
      );
      _passwordStrength = PasswordGenerator.calculateStrength(_generatedPassword);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('密码生成器'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPasswordDisplay(),
          const SizedBox(height: 24),
          _buildLengthSlider(),
          const SizedBox(height: 24),
          _buildOptions(),
          const SizedBox(height: 24),
          _buildStrengthIndicator(),
          const SizedBox(height: 32),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildPasswordDisplay() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.rule),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  _generatedPassword,
                  style: const TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 20,
                    color: AppColors.ink,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1,
                  ),
                ),
              ),
              IconButton(
                onPressed: _generatePassword,
                icon: const Icon(Icons.refresh, color: AppColors.accent),
                tooltip: '重新生成',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildCopyButton('复制密码', _generatedPassword),
              const SizedBox(width: 8),
              _buildCopyButton('复制并关闭', _generatedPassword, closeAfterCopy: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCopyButton(String label, String text, {bool closeAfterCopy = false}) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: () {
          SecureClipboard.copy(text);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('密码已复制，30 秒后自动清除')),
          );
          if (closeAfterCopy) {
            Navigator.pop(context, text);
          }
        },
        icon: const Icon(Icons.copy, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 12)),
      ),
    );
  }

  Widget _buildLengthSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '密码长度',
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(
              width: 60,
              child: TextFormField(
                controller: _lengthController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.rule),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.rule),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.accent),
                  ),
                ),
                onChanged: (_) => _generatePassword(),
              ),
            ),
          ],
        ),
        Slider(
          value: (int.tryParse(_lengthController.text) ?? 16).toDouble().clamp(4, 64),
          min: 4,
          max: 64,
          divisions: 60,
          activeColor: AppColors.accent,
          inactiveColor: AppColors.rule,
          onChanged: (value) {
            setState(() {
              _lengthController.text = value.round().toString();
            });
            _generatePassword();
          },
        ),
      ],
    );
  }

  Widget _buildOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '字符选项',
          style: TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _buildOptionTile(
          title: '小写字母 (a-z)',
          value: _includeLowercase,
          onChanged: (value) {
            setState(() => _includeLowercase = value);
            _generatePassword();
          },
          example: 'abc',
        ),
        const SizedBox(height: 8),
        _buildOptionTile(
          title: '大写字母 (A-Z)',
          value: _includeUppercase,
          onChanged: (value) {
            setState(() => _includeUppercase = value);
            _generatePassword();
          },
          example: 'ABC',
        ),
        const SizedBox(height: 8),
        _buildOptionTile(
          title: '数字 (0-9)',
          value: _includeNumbers,
          onChanged: (value) {
            setState(() => _includeNumbers = value);
            _generatePassword();
          },
          example: '123',
        ),
        const SizedBox(height: 8),
        _buildOptionTile(
          title: '特殊符号 (!@#\$%)',
          value: _includeSymbols,
          onChanged: (value) {
            setState(() => _includeSymbols = value);
            _generatePassword();
          },
          example: '!@#',
        ),
      ],
    );
  }

  Widget _buildOptionTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required String example,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.rule),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: AppColors.ink),
                ),
                Text(
                  example,
                  style: TextStyle(
                    color: AppColors.muted.withOpacity(0.7),
                    fontSize: 12,
                    fontFamily: 'JetBrainsMono',
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.accent,
          ),
        ],
      ),
    );
  }

  Widget _buildStrengthIndicator() {
    final label = PasswordGenerator.getStrengthLabel(_passwordStrength);
    final color = _getStrengthColor(_passwordStrength);

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '密码强度评估',
                style: TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _passwordStrength,
              backgroundColor: AppColors.rule,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          _buildEntropyInfo(),
        ],
      ),
    );
  }

  Widget _buildEntropyInfo() {
    final length = _generatedPassword.length;
    final charsetSize = _calculateCharsetSize();
    final entropy = length * (charsetSize > 0 ? (charsetSize.bitLength - 1) : 0);

    return Row(
      children: [
        Expanded(
          child: _buildInfoItem('长度', '$length'),
        ),
        Expanded(
          child: _buildInfoItem('字符集大小', '$charsetSize'),
        ),
        Expanded(
          child: _buildInfoItem('熵位数', '$entropy'),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.accent,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  int _calculateCharsetSize() {
    int size = 0;
    if (_includeLowercase) size += 26;
    if (_includeUppercase) size += 26;
    if (_includeNumbers) size += 10;
    if (_includeSymbols) size += 32;
    return size;
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _generatePassword,
            icon: const Icon(Icons.refresh),
            label: const Text('重新生成'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context, _generatedPassword);
            },
            icon: const Icon(Icons.check),
            label: const Text('使用此密码'),
          ),
        ),
      ],
    );
  }

  Color _getStrengthColor(double strength) {
    if (strength < 0.3) return AppColors.error;
    if (strength < 0.5) return AppColors.warning;
    if (strength < 0.7) return AppColors.accent2;
    if (strength < 0.9) return const Color(0xFF84cc16);
    return AppColors.success;
  }
}

extension on int {
  int get bitLength {
    if (this <= 0) return 0;
    return this.toRadixString(2).length;
  }
}
