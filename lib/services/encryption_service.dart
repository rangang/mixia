import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';

class EncryptionService {
  static const _formatPrefix = 'mx2:';
  static const _passwordPrefix = 'argon2id:';
  static const int _keyLength = 32;
  static const int _saltLength = 16;
  static const int _nonceLength = 12;
  static const int _argonIterations = 3;
  static const int _argonMemoryKb = 64 * 1024;

  static Uint8List generateSalt() {
    final random = Random.secure();
    return Uint8List.fromList(
      List.generate(_saltLength, (_) => random.nextInt(256)),
    );
  }

  static Uint8List deriveKey(String password, Uint8List salt) {
    final parameters = Argon2Parameters(
      Argon2Parameters.ARGON2_id,
      salt,
      desiredKeyLength: _keyLength,
      iterations: _argonIterations,
      memory: _argonMemoryKb,
      lanes: 1,
      version: Argon2Parameters.ARGON2_VERSION_13,
    );
    final generator = Argon2BytesGenerator()..init(parameters);
    final key = Uint8List(_keyLength);
    generator.generateBytes(
      Uint8List.fromList(utf8.encode(password)),
      key,
      0,
      key.length,
    );
    return key;
  }

  static String encrypt(String plaintext, String password) {
    final salt = generateSalt();
    final nonce = _randomBytes(_nonceLength);
    final key = deriveKey(password, salt);
    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        true,
        AEADParameters(
          KeyParameter(key),
          128,
          nonce,
          Uint8List.fromList(utf8.encode(_formatPrefix)),
        ),
      );
    final encrypted = cipher.process(Uint8List.fromList(utf8.encode(plaintext)));
    final payload = BytesBuilder()
      ..add(salt)
      ..add(nonce)
      ..add(encrypted);
    return '$_formatPrefix${hex.encode(payload.toBytes())}';
  }

  static String decrypt(String ciphertext, String password) {
    if (!ciphertext.startsWith(_formatPrefix)) {
      return _legacyDecrypt(ciphertext, password);
    }

    final bytes = Uint8List.fromList(
      hex.decode(ciphertext.substring(_formatPrefix.length)),
    );
    if (bytes.length < _saltLength + _nonceLength + 16) {
      throw const FormatException('加密数据不完整');
    }

    final salt = bytes.sublist(0, _saltLength);
    final nonce = bytes.sublist(_saltLength, _saltLength + _nonceLength);
    final encrypted = bytes.sublist(_saltLength + _nonceLength);
    final key = deriveKey(password, salt);
    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        false,
        AEADParameters(
          KeyParameter(key),
          128,
          nonce,
          Uint8List.fromList(utf8.encode(_formatPrefix)),
        ),
      );
    return utf8.decode(cipher.process(encrypted));
  }

  static String hashPassword(String password) {
    final salt = generateSalt();
    final hash = deriveKey(password, salt);
    return '$_passwordPrefix${hex.encode(salt)}:${hex.encode(hash)}';
  }

  static bool verifyPassword(String password, String storedHash) {
    if (!storedHash.startsWith(_passwordPrefix)) {
      return _constantTimeEquals(
        Uint8List.fromList(sha256.convert(utf8.encode(password)).bytes),
        Uint8List.fromList(hex.decode(storedHash)),
      );
    }

    final parts = storedHash.split(':');
    if (parts.length != 3) return false;
    final salt = Uint8List.fromList(hex.decode(parts[1]));
    final expected = Uint8List.fromList(hex.decode(parts[2]));
    return _constantTimeEquals(deriveKey(password, salt), expected);
  }

  static Uint8List _randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List.generate(length, (_) => random.nextInt(256)),
    );
  }

  static bool _constantTimeEquals(Uint8List left, Uint8List right) {
    if (left.length != right.length) return false;
    var difference = 0;
    for (var i = 0; i < left.length; i++) {
      difference |= left[i] ^ right[i];
    }
    return difference == 0;
  }

  // Keeps existing local vaults readable once; the next save upgrades them.
  static String _legacyDecrypt(String ciphertext, String password) {
    final bytes = Uint8List.fromList(hex.decode(ciphertext));
    if (bytes.length < _saltLength + _nonceLength) {
      throw const FormatException('旧版加密数据不完整');
    }
    final salt = bytes.sublist(0, _saltLength);
    final nonce = bytes.sublist(_saltLength, _saltLength + _nonceLength);
    final encrypted = bytes.sublist(_saltLength + _nonceLength);
    final key = _legacyDeriveKey(password, salt);
    final keystream = _legacyKeystream(key, nonce, encrypted.length);
    final decrypted = Uint8List(encrypted.length);
    for (var i = 0; i < encrypted.length; i++) {
      decrypted[i] = encrypted[i] ^ keystream[i];
    }
    return utf8.decode(decrypted);
  }

  static Uint8List _legacyDeriveKey(String password, Uint8List salt) {
    final combined = Uint8List.fromList([...utf8.encode(password), ...salt]);
    var hash = Uint8List.fromList(sha256.convert(combined).bytes);
    for (var i = 0; i < 3; i++) {
      hash = Uint8List.fromList(sha256.convert(hash).bytes);
    }
    return Uint8List.fromList(hash.take(_keyLength).toList());
  }

  static Uint8List _legacyKeystream(
    Uint8List key,
    Uint8List nonce,
    int length,
  ) {
    final keystream = Uint8List(length);
    var counter = 0;
    for (var i = 0; i < length; i += key.length) {
      final block = Uint8List.fromList([
        ...nonce,
        (counter >> 24) & 0xFF,
        (counter >> 16) & 0xFF,
        (counter >> 8) & 0xFF,
        counter & 0xFF,
      ]);
      final hash = sha256.convert(block).bytes;
      final copyLength = min(length - i, hash.length);
      keystream.setRange(i, i + copyLength, hash.take(copyLength));
      counter++;
    }
    return keystream;
  }
}
