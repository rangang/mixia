import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:convert/convert.dart';

class EncryptionService {
  static const int _keyLength = 32;
  static const int _saltLength = 16;
  static const int _nonceLength = 12;
  static const int _iterations = 3;

  static Uint8List generateSalt() {
    final random = Random.secure();
    return Uint8List.fromList(
      List.generate(_saltLength, (_) => random.nextInt(256)),
    );
  }

  static Uint8List deriveKey(String password, Uint8List salt) {
    final passwordBytes = utf8.encode(password);

    final combined = Uint8List(passwordBytes.length + salt.length);
    combined.setRange(0, passwordBytes.length, passwordBytes);
    combined.setRange(passwordBytes.length, combined.length, salt);

    var hash = Uint8List.fromList(sha256.convert(combined).bytes);

    for (var i = 0; i < _iterations; i++) {
      hash = Uint8List.fromList(sha256.convert(hash).bytes);
    }

    return Uint8List.fromList(hash.take(_keyLength).toList());
  }

  static String encrypt(String plaintext, String password) {
    final salt = generateSalt();
    final key = deriveKey(password, salt);

    final plaintextBytes = Uint8List.fromList(utf8.encode(plaintext));
    final nonce = _generateNonce();

    final encrypted = _xorEncrypt(plaintextBytes, key, nonce);

    final result = BytesBuilder();
    result.add(salt);
    result.add(nonce);
    result.add(encrypted);

    return hex.encode(result.toBytes());
  }

  static String decrypt(String ciphertext, String password) {
    final bytes = Uint8List.fromList(hex.decode(ciphertext));

    final salt = bytes.sublist(0, _saltLength);
    final nonce = bytes.sublist(_saltLength, _saltLength + _nonceLength);
    final encrypted = bytes.sublist(_saltLength + _nonceLength);

    final key = deriveKey(password, salt);

    final decrypted = _xorDecrypt(encrypted, key, nonce);

    return utf8.decode(decrypted);
  }

  static Uint8List _generateNonce() {
    final random = Random.secure();
    return Uint8List.fromList(
      List.generate(_nonceLength, (_) => random.nextInt(256)),
    );
  }

  static Uint8List _xorEncrypt(
      Uint8List plaintext, Uint8List key, Uint8List nonce) {
    final result = Uint8List(plaintext.length);
    final keystream = _generateKeystream(key, nonce, plaintext.length);

    for (var i = 0; i < plaintext.length; i++) {
      result[i] = plaintext[i] ^ keystream[i];
    }

    return result;
  }

  static Uint8List _xorDecrypt(
      Uint8List ciphertext, Uint8List key, Uint8List nonce) {
    return _xorEncrypt(ciphertext, key, nonce);
  }

  static Uint8List _generateKeystream(
      Uint8List key, Uint8List nonce, int length) {
    final keystream = Uint8List(length);
    var counter = 0;

    for (var i = 0; i < length; i += key.length) {
      final block = BytesBuilder();
      block.add(nonce);
      block.add(_intToBytes(counter));

      final hash = Uint8List.fromList(sha256.convert(block.toBytes()).bytes);
      final remaining = length - i;
      final copyLength = remaining < hash.length ? remaining : hash.length;

      keystream.setRange(i, i + copyLength, hash.take(copyLength));
      counter++;
    }

    return keystream;
  }

  static Uint8List _intToBytes(int value) {
    return Uint8List.fromList([
      (value >> 24) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 8) & 0xFF,
      value & 0xFF,
    ]);
  }

  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  static bool verifyPassword(String password, String hash) {
    return hashPassword(password) == hash;
  }
}
