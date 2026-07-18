import 'dart:async';

import 'package:flutter/services.dart';

class SecureClipboard {
  static const clearDelay = Duration(seconds: 30);
  static Timer? _clearTimer;

  static Future<void> copy(String value) async {
    _clearTimer?.cancel();
    await Clipboard.setData(ClipboardData(text: value));
    _clearTimer = Timer(clearDelay, () async {
      final current = await Clipboard.getData(Clipboard.kTextPlain);
      if (current?.text == value) {
        await Clipboard.setData(const ClipboardData(text: ''));
      }
    });
  }
}
