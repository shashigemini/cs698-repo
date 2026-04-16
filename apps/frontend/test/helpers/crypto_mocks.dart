import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:frontend/core/services/cryptography_service.dart';
import 'package:frontend/core/services/session_key_store.dart';
import 'package:frontend/core/services/recovery_service.dart';
import 'package:mocktail/mocktail.dart';

class MockCryptographyService extends Mock implements CryptographyService {}

class MockSessionKeyStore extends Mock implements SessionKeyStore {}

class FakeSessionKeyStore extends Fake implements SessionKeyStore {
  SecretKey? _accountKey;
  SecretKey? _masterKey;

  @override
  void setAccountKey(SecretKey key) => _accountKey = key;
  @override
  void setMasterKey(SecretKey key) => _masterKey = key;
  @override
  void clear() {
    _accountKey = null;
    _masterKey = null;
  }

  @override
  SecretKey? get currentAccountKey => _accountKey;
  @override
  SecretKey? get currentMasterKey => _masterKey;
}

/// Registers required mocktail fallbacks for crypto types (Rule 3.2)
void registerCryptoFallbackValues() {
  registerFallbackValue(const <int>[]);
}

/// A helper that provides real but simple recovery for tests.
class MockRecoveryService extends Mock implements RecoveryService {}

class FakeRecoveryService extends Fake implements RecoveryService {
  @override
  String keyToMnemonic(List<int> keyBytes) => 'fake-mnemonic-phrase';

  @override
  List<int> mnemonicToKey(String mnemonic) => List<int>.filled(16, 0);

  @override
  Future<SecretKey> generateRecoveryKey() async =>
      SecretKey(List.filled(16, 0));
}

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
    // Simple XOR/Concat simulation for testing re-wrap
    final keyBytes = await keyToWrap.extractBytes();
    final wrapperBytes = await wrappingKey.extractBytes();
    final result = List<int>.generate(
      keyBytes.length,
      (i) => keyBytes[i] ^ (wrapperBytes[i % wrapperBytes.length]),
    );
    return 'wrapped-${base64.encode(result)}';
  }

  @override
  Future<SecretKey> unwrapKey(
    String wrappedKeyBase64,
    SecretKey wrappingKey, {
    List<int>? aad,
  }) async {
    if (!wrappedKeyBase64.startsWith('wrapped-')) {
      throw Exception('Invalid wrapped key format');
    }
    final encoded = wrappedKeyBase64.replaceFirst('wrapped-', '');
    final wrappedBytes = base64.decode(encoded);
    final wrapperBytes = await wrappingKey.extractBytes();
    final result = List<int>.generate(
      wrappedBytes.length,
      (i) => wrappedBytes[i] ^ (wrapperBytes[i % wrapperBytes.length]),
    );
    return SecretKey(result);
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

  @override
  Future<SecretKey> expandKey(SecretKey key) async {
    // HKDF expand simulation: pad/hash the key to 32 bytes
    final bytes = await key.extractBytes();
    final expanded = List<int>.generate(32, (i) => bytes[i % bytes.length] ^ i);
    return SecretKey(expanded);
  }
}
