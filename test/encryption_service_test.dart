import 'package:flutter_test/flutter_test.dart';
import 'package:mi_xia/services/encryption_service.dart';

void main() {
  test('AES-GCM round trip preserves unicode content', () {
    const plaintext = '{"title":"密匣","password":"S3cret!"}';
    const password = 'correct horse battery staple';

    final encrypted = EncryptionService.encrypt(plaintext, password);

    expect(encrypted, startsWith('mx2:'));
    expect(EncryptionService.decrypt(encrypted, password), plaintext);
  });

  test('AES-GCM rejects a modified ciphertext', () {
    const password = 'correct horse battery staple';
    final encrypted = EncryptionService.encrypt('sensitive', password);
    final replacement = encrypted.endsWith('0') ? '1' : '0';
    final tampered =
        encrypted.substring(0, encrypted.length - 1) + replacement;

    expect(
      () => EncryptionService.decrypt(tampered, password),
      throwsA(anything),
    );
  });

  test('Argon2id password verifier accepts only the original password', () {
    final hash = EncryptionService.hashPassword('master password');

    expect(hash, startsWith('argon2id:'));
    expect(EncryptionService.verifyPassword('master password', hash), isTrue);
    expect(EncryptionService.verifyPassword('wrong password', hash), isFalse);
  });
}
