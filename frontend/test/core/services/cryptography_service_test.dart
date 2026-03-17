import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/services/cryptography_service.dart';

void main() {
  late CryptographyService crypto;

  setUp(() {
    crypto = CryptographyService();
  });

  group('CryptographyService', () {
    test(
      'deriveLocalMasterKey produces stable output for same password/salt',
      () async {
        const password = 'test-password';
        final salt = utf8.encode('test-salt');

        final key1 = await crypto.deriveLocalMasterKey(password, salt);
        final key2 = await crypto.deriveLocalMasterKey(password, salt);

        final bytes1 = await key1.extractBytes();
        final bytes2 = await key2.extractBytes();

        expect(bytes1, bytes2);
      },
    );

    test('deriveAuthToken produces different token from LMK', () async {
      final lmk = SecretKey(List.generate(32, (i) => i));
      final token = await crypto.deriveAuthToken(lmk);

      expect(token, isNotEmpty);
      expect(
        token,
        isNot(contains(base64Url.encode(await lmk.extractBytes()))),
      );
    });

    test('wrap and unwrap key works', () async {
      final masterKey = await crypto.generateRandomKey();
      final targetKey = await crypto.generateRandomKey();
      const aadString = 'wrapping-context';
      final aad = utf8.encode(aadString);

      final wrapped = await crypto.wrapKey(targetKey, masterKey, aad: aad);
      final unwrapped = await crypto.unwrapKey(wrapped, masterKey, aad: aad);

      expect(await unwrapped.extractBytes(), await targetKey.extractBytes());
    });

    test('unwrap fails if AAD is different', () async {
      final masterKey = await crypto.generateRandomKey();
      final targetKey = await crypto.generateRandomKey();

      final wrapped = await crypto.wrapKey(
        targetKey,
        masterKey,
        aad: utf8.encode('aad1'),
      );

      expect(
        () => crypto.unwrapKey(wrapped, masterKey, aad: utf8.encode('aad2')),
        throwsA(isA<Exception>()),
      );
    });

    test('encryptContent and decryptContent works with AAD binding', () async {
      final key = await crypto.generateRandomKey();
      const content = 'Secret spirit message';
      const convId = 'conv-123';
      const msgId = 'msg-456';

      final encrypted = await crypto.encryptContent(
        content,
        key,
        aad: utf8.encode('$convId:$msgId'),
      );

      final decrypted = await crypto.decryptContent(
        encrypted,
        key,
        aad: utf8.encode('$convId:$msgId'),
      );

      expect(decrypted, content);
    });

    test('decryptContent fails if context (AAD) is swapped', () async {
      final key = await crypto.generateRandomKey();
      const content = 'Secret spirit message';

      final encrypted = await crypto.encryptContent(
        content,
        key,
        aad: utf8.encode('conv-A:msg-1'),
      );

      // Attempt to decrypt as if it belongs to conv-B
      expect(
        () => crypto.decryptContent(
          encrypted,
          key,
          aad: utf8.encode('conv-B:msg-1'),
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
