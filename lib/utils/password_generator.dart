import 'dart:math';
import 'package:flutter/material.dart';

class PasswordGenerator {
  static const String _lowercase = 'abcdefghijklmnopqrstuvwxyz';
  static const String _uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _numbers = '0123456789';
  static const String _symbols = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

  static String generate({
    int length = 16,
    bool includeLowercase = true,
    bool includeUppercase = true,
    bool includeNumbers = true,
    bool includeSymbols = true,
    String? customCharset,
  }) {
    String charset = '';

    if (customCharset != null && customCharset.isNotEmpty) {
      charset = customCharset;
    } else {
      if (includeLowercase) charset += _lowercase;
      if (includeUppercase) charset += _uppercase;
      if (includeNumbers) charset += _numbers;
      if (includeSymbols) charset += _symbols;
    }

    if (charset.isEmpty) {
      charset = _lowercase + _uppercase + _numbers;
    }

    final random = Random.secure();
    final password = List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    );

    return password.join();
  }

  static double calculateStrength(String password) {
    if (password.isEmpty) return 0.0;

    double strength = 0.0;

    if (password.length >= 8) strength += 0.2;
    if (password.length >= 12) strength += 0.1;
    if (password.length >= 16) strength += 0.1;

    if (password.contains(RegExp(r'[a-z]'))) strength += 0.15;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.15;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.15;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.15;

    return strength.clamp(0.0, 1.0);
  }

  static String getStrengthLabel(double strength) {
    if (strength < 0.3) return '非常弱';
    if (strength < 0.5) return '弱';
    if (strength < 0.7) return '中等';
    if (strength < 0.9) return '强';
    return '非常强';
  }

  static Color getStrengthColor(double strength) {
    if (strength < 0.3) return const Color(0xFFef4444);
    if (strength < 0.5) return const Color(0xFFf97316);
    if (strength < 0.7) return const Color(0xFFf59e0b);
    if (strength < 0.9) return const Color(0xFF84cc16);
    return const Color(0xFF22c55e);
  }

  static List<String> analyzeWeaknesses(String password) {
    final weaknesses = <String>[];

    if (password.length < 8) {
      addWeakness(weaknesses, '密码长度不足8位');
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      addWeakness(weaknesses, '缺少小写字母');
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      addWeakness(weaknesses, '缺少大写字母');
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      addWeakness(weaknesses, '缺少数字');
    }
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      addWeakness(weaknesses, '缺少特殊符号');
    }
    if (password.contains(RegExp(r'(.)\1{2,}'))) {
      addWeakness(weaknesses, '存在连续重复字符');
    }
    if (password.contains(RegExp(r'(012|123|234|345|456|567|678|789|890)'))) {
      addWeakness(weaknesses, '存在连续数字序列');
    }
    if (password.contains(RegExp(r'(abc|bcd|cde|def|efg|fgh|ghi|hij|ijk|jkl|klm|lmn|mno|nop|opq|pqr|qrs|rst|stu|tuv|uvw|vwx|wxy|xyz)', caseSensitive: false))) {
      addWeakness(weaknesses, '存在连续字母序列');
    }

    return weaknesses;
  }

  static void addWeakness(List<String> weaknesses, String weakness) {
    weaknesses.add(weakness);
  }
}
