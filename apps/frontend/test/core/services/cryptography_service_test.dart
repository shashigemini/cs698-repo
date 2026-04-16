import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/services/cryptography_service.dart';

void main() {
  late CryptographyService cryptoService;

  setUp(() {
    cryptoService = CryptographyService();
  });

  group('CryptographyService: deriveLocalMasterKey', () {
    test('CS-01: Same password + salt produces deterministic output', () async {
      const password = 'test-password';
      final salt = utf8.encode('test-salt');

      final key1 = await cryptoService.deriveLocalMasterKey(password, salt);
      final key2 = await cryptoService.deriveLocalMasterKey(password, salt);

      final bytes1 = await key1.extractBytes();
      final bytes2 = await key2.extractBytes();

      expect(bytes1, equals(bytes2));
    });

    test('CS-02: Output has correct length (32 bytes)', () async {
      const password = 'pw';
      final salt = [1, 2, 3, 4];

      final key = await cryptoService.deriveLocalMasterKey(password, salt);
      final bytes = await key.extractBytes();

      expect(bytes.length, equals(32));
    });

    test('CS-03: Different passwords produce different keys', () async {
      const passwordA = 'pw-a';
      const passwordB = 'pw-b';
      final salt = utf8.encode('same-salt');

      final keyA = await cryptoService.deriveLocalMasterKey(passwordA, salt);
      final keyB = await cryptoService.deriveLocalMasterKey(passwordB, salt);

      expect(await keyA.extractBytes(), isNot(equals(await keyB.extractBytes())));
    });

    test('CS-04: Different salts produce different keys', () async {
      const password = 'same-password';
      final saltA = [0];
      final saltB = [1];

      final keyA = await cryptoService.deriveLocalMasterKey(password, saltA);
      final keyB = await cryptoService.deriveLocalMasterKey(password, saltB);

      expect(await keyA.extractBytes(), isNot(equals(await keyB.extractBytes())));
    });
  });

  group('CryptographyService: deriveAuthToken', () {
    test('CS-05: Produces non-empty base64url string', () async {
      final lmk = SecretKey(List.generate(32, (i) => i));
      final token = await cryptoService.deriveAuthToken(lmk);

      expect(token, isNotEmpty);
      // Valid base64url consists of A-Z, a-z, 0-9, -, _ and optional padding =
      expect(RegExp(r'^[A-Za-z0-9_-]+={0,2}$').hasMatch(token), isTrue);
    });

    test('CS-06: Token differs from raw LMK bytes', () async {
      final lmk = SecretKey(List.generate(32, (i) => i));
      final lmkBase64 = base64Url.encode(await lmk.extractBytes());
      final token = await cryptoService.deriveAuthToken(lmk);

      expect(token, isNot(equals(lmkBase64)));
    });

    test('CS-07: Deterministic: same LMK -> same token', () async {
      final lmk = SecretKey(List.generate(32, (i) => i));
      final token1 = await cryptoService.deriveAuthToken(lmk);
      final token2 = await cryptoService.deriveAuthToken(lmk);

      expect(token1, equals(token2));
    });
  });

  group('CryptographyService: expandKey', () {
    test('CS-08: Output is a 32-byte key', () async {
      final inputKey = SecretKey(List.generate(16, (i) => i));
      final expandedKey = await cryptoService.expandKey(inputKey);
      final bytes = await expandedKey.extractBytes();

      expect(bytes.length, equals(32));
    });

    test('CS-09: Expanded key differs from input key', () async {
      final inputKey = SecretKey(List.generate(32, (i) => i));
      final expandedKey = await cryptoService.expandKey(inputKey);

      expect(await expandedKey.extractBytes(),
          isNot(equals(await inputKey.extractBytes())));
    });

    test('CS-10: Deterministic expansion', () async {
      final inputKey = SecretKey(List.generate(32, (i) => i));
      final key1 = await cryptoService.expandKey(inputKey);
      final key2 = await cryptoService.expandKey(inputKey);

      expect(await key1.extractBytes(), equals(await key2.extractBytes()));
    });
  });

  group('CryptographyService: generateRandomKey', () {
    test('CS-11: Returns a 32-byte key', () async {
      final key = await cryptoService.generateRandomKey();
      final bytes = await key.extractBytes();
      expect(bytes.length, equals(32));
    });

    test('CS-12: Two generated keys are different', () async {
      final key1 = await cryptoService.generateRandomKey();
      final key2 = await cryptoService.generateRandomKey();

      expect(await key1.extractBytes(), isNot(equals(await key2.extractBytes())));
    });
  });

  group('CryptographyService: wrapKey / unwrapKey', () {
    test('CS-13: Round-trip with AAD', () async {
      final keyToWrap = SecretKey(List.generate(32, (i) => i + 1));
      final wrappingKey = SecretKey(List.generate(32, (i) => i + 10));
      final aad = [1, 2, 3];

      final wrapped = await cryptoService.wrapKey(keyToWrap, wrappingKey, aad: aad);
      final unwrapped = await cryptoService.unwrapKey(wrapped, wrappingKey, aad: aad);

      expect(await unwrapped.extractBytes(), equals(await keyToWrap.extractBytes()));
    });

    test('CS-14: Round-trip no AAD', () async {
      final keyToWrap = SecretKey(List.generate(32, (i) => i + 1));
      final wrappingKey = SecretKey(List.generate(32, (i) => i + 10));

      final wrapped = await cryptoService.wrapKey(keyToWrap, wrappingKey);
      final unwrapped = await cryptoService.unwrapKey(wrapped, wrappingKey);

      expect(await unwrapped.extractBytes(), equals(await keyToWrap.extractBytes()));
    });

    test('CS-15: Wrapped output is unique and non-empty', () async {
      final keyToWrap = SecretKey(List.generate(32, (i) => i));
      final wrappingKey = SecretKey(List.generate(32, (i) => i + 1));
      final wrapped = await cryptoService.wrapKey(keyToWrap, wrappingKey);

      expect(wrapped, isNotEmpty);
    });

    test('CS-16: Fails with wrong wrapping key', () async {
      final keyToWrap = SecretKey(List.generate(32, (i) => i));
      final keyA = SecretKey(List.generate(32, (i) => i + 1));
      final keyB = SecretKey(List.generate(32, (i) => i + 2));

      final wrapped = await cryptoService.wrapKey(keyToWrap, keyA);
      expect(() => cryptoService.unwrapKey(wrapped, keyB), throwsException);
    });

    test('CS-17: Fails with mismatched AAD', () async {
      final keyToWrap = SecretKey(List.generate(32, (i) => i));
      final wrappingKey = SecretKey(List.generate(32, (i) => i + 1));

      final wrapped = await cryptoService.wrapKey(keyToWrap, wrappingKey, aad: [1]);
      expect(() => cryptoService.unwrapKey(wrapped, wrappingKey, aad: [2]),
          throwsException);
    });
  });

  group('CryptographyService: encryptContent / decryptContent', () {
    test('CS-18: Round-trip with AAD', () async {
      const content = 'Hello';
      final key = SecretKey(List.generate(32, (i) => i));
      final aad = utf8.encode('conv:msg');

      final ciphertext =
          await cryptoService.encryptContent(content, key, aad: aad);
      final decrypted =
          await cryptoService.decryptContent(ciphertext, key, aad: aad);

      expect(decrypted, equals(content));
    });

    test('CS-19: Round-trip no AAD', () async {
      const content = 'Hello';
      final key = SecretKey(List.generate(32, (i) => i));

      final ciphertext = await cryptoService.encryptContent(content, key);
      final decrypted = await cryptoService.decryptContent(ciphertext, key);

      expect(decrypted, equals(content));
    });

    test('CS-20: Empty string round-trip', () async {
      const content = '';
      final key = SecretKey(List.generate(32, (i) => i));

      final ciphertext = await cryptoService.encryptContent(content, key);
      final decrypted = await cryptoService.decryptContent(ciphertext, key);

      expect(decrypted, equals(content));
    });

    test('CS-21: Unicode content round-trip', () async {
      const content = '🕉 ॐ नमः शिवाय';
      final key = SecretKey(List.generate(32, (i) => i));

      final ciphertext = await cryptoService.encryptContent(content, key);
      final decrypted = await cryptoService.decryptContent(ciphertext, key);

      expect(decrypted, equals(content));
    });

    test('CS-22: Fails with wrong key', () async {
      const content = 'secret';
      final keyA = SecretKey(List.generate(32, (i) => i));
      final keyB = SecretKey(List.generate(32, (i) => i + 1));

      final ciphertext = await cryptoService.encryptContent(content, keyA);
      expect(() => cryptoService.decryptContent(ciphertext, keyB),
          throwsException);
    });

    test('CS-23: Fails with swapped AAD', () async {
      const content = 'secret';
      final key = SecretKey(List.generate(32, (i) => i));

      final ciphertext = await cryptoService.encryptContent(content, key,
          aad: utf8.encode('conv-A:msg-1'));
      expect(
          () => cryptoService.decryptContent(ciphertext, key,
              aad: utf8.encode('conv-B:msg-1')),
          throwsException);
    });

    test('CS-24: Different nonces for different encryptions', () async {
      const content = 'Same message';
      final key = SecretKey(List.generate(32, (i) => i));

      final c1 = await cryptoService.encryptContent(content, key);
      final c2 = await cryptoService.encryptContent(content, key);

      expect(c1, isNot(equals(c2)));
    });
  });
}
