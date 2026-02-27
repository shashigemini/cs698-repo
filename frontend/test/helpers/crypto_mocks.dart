import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:frontend/core/services/cryptography_service.dart';
import 'package:frontend/core/services/session_key_store.dart';
import 'package:mocktail/mocktail.dart';

class MockCryptographyService extends Mock implements CryptographyService {}

class MockSessionKeyStore extends Mock implements SessionKeyStore {}

/// A helper that provides real but simple crypto for tests if needed.
class FakeCryptographyService extends Fake implements CryptographyService {
  @override
  Future<SecretKey> deriveLocalMasterKey(
    String password,
    List<int> salt,
  ) async {
    // Return a key that is the hash of password + salt for pseudo-reality
    final bytes = List<int>.filled(32, 0);
    final passwordBytes = password.codeUnits;
    for (var i = 0; i < passwordBytes.length && i < 32; i++) {
      bytes[i] = passwordBytes[i] ^ (salt.length > i ? salt[i] : 0);
    }
    return SecretKey(bytes);
  }

  @override
  Future<String> deriveAuthToken(SecretKey lmk) async {
    final bytes = await lmk.extractBytes();
    return 'mock-auth-token-${bytes.join().hashCode}';
  }

  @override
  Future<SecretKey> generateRandomKey() async {
    return SecretKey(List.generate(32, (i) => i));
  }

  @override
  Future<String> wrapKey(
    SecretKey keyToWrap,
    SecretKey wrappingKey, {
    List<int>? aad,
  }) async {
    return 'wrapped-key';
  }

  @override
  Future<SecretKey> unwrapKey(
    String wrappedKeyBase64,
    SecretKey wrappingKey, {
    List<int>? aad,
  }) async {
    return SecretKey(List.generate(32, (i) => i));
  }

  @override
  Future<String> encryptContent(
    String content,
    SecretKey key, {
    List<int>? aad,
  }) async {
    // Fake encryption simply prefixes the content
    final aadString = aad != null ? utf8.decode(aad) : 'no_aad';
    return 'encrypted_${aadString}_$content';
  }

  @override
  Future<String> decryptContent(
    String ciphertextBase64,
    SecretKey key, {
    List<int>? aad,
  }) async {
    // Fake decryption removes the prefix
    final aadString = aad != null ? utf8.decode(aad) : 'no_aad';
    final prefix = 'encrypted_${aadString}_';
    if (ciphertextBase64.startsWith(prefix)) {
      return ciphertextBase64.substring(prefix.length);
    }
    return ciphertextBase64; // Fallback if it wasn't fake-encrypted
  }
}
