import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import '../utils/app_logger.dart';

/// Top-level function for `compute()` to execute Argon2id derivation in an Isolate.
/// Receives primitive arguments and returns raw bytes.
Future<List<int>> _deriveKeyRoutine(Map<String, dynamic> args) async {
  final password = args['password'] as String;
  final salt = args['salt'] as List<int>;
  final isWeb = args['isWeb'] as bool;

  // Re-instantiate locally for the Isolate
  final argon2 = Argon2id(
    parallelism: 1,
    memory: isWeb
        ? 16384
        : 65536, // 16 MB on Web to prevent slow-downs, 64 MB native
    iterations: isWeb ? 1 : 3, // 1 Iteration on Web, 3 natively
    hashLength: 32,
  );

  final secretKey = await argon2.deriveKeyFromPassword(
    password: password,
    nonce: salt,
  );

  return secretKey.extractBytes();
}

/// Service providing cryptographic primitives for End-to-End Encryption (E2EE).
///
/// Uses the `cryptography` package to orchestrate reputable algorithms like
/// Argon2id for key derivation and AES-GCM/XChaCha20 for encryption.
class CryptographyService {
  final _aesGcm = AesGcm.with256bits();

  /// Derives a [LocalMasterKey] (LMK) from a [password] and [salt].
  ///
  /// The LMK is used locally and never sent to the server.
  Future<SecretKey> deriveLocalMasterKey(
    String password,
    List<int> salt,
  ) async {
    AppLogger.d('CryptographyService: Deriving LMK via Argon2id (Isolate)');

    // We send primitive data to the background isolate to prevent UI freezing.
    final rawBytes = await compute(_deriveKeyRoutine, {
      'password': password,
      'salt': salt,
      'isWeb': kIsWeb,
    });

    return SecretKey(rawBytes);
  }

  /// Derives a [ClientAuthToken] from the [lmk].
  ///
  /// This token is sent to the server for authentication.
  Future<String> deriveAuthToken(SecretKey lmk) async {
    // We use a fixed purpose string to salt the HKDF derivation
    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
    final output = await hkdf.deriveKey(
      secretKey: lmk,
      info: utf8.encode('auth_token_derivation'),
    );
    final bytes = await output.extractBytes();
    return base64Url.encode(bytes);
  }

  /// Expands a key (e.g. 128-bit to 256-bit) using HKDF.
  Future<SecretKey> expandKey(SecretKey key) async {
    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
    return hkdf.deriveKey(secretKey: key, info: utf8.encode('key_expansion'));
  }

  /// Generates a random [AccountKey] or [ConversationKey].
  Future<SecretKey> generateRandomKey() async {
    return _aesGcm.newSecretKey();
  }

  /// Wraps (encrypts) a [keyToWrap] with a [wrappingKey].
  ///
  /// Optionally takes [aad] (Additional Authenticated Data).
  Future<String> wrapKey(
    SecretKey keyToWrap,
    SecretKey wrappingKey, {
    List<int>? aad,
  }) async {
    final keyBytes = await keyToWrap.extractBytes();
    final secretBox = await _aesGcm.encrypt(
      keyBytes,
      secretKey: wrappingKey,
      aad: aad ?? const [],
    );
    return base64Url.encode(secretBox.concatenation());
  }

  /// Unwraps (decrypts) a [wrappedKeyBase64] using a [wrappingKey].
  Future<SecretKey> unwrapKey(
    String wrappedKeyBase64,
    SecretKey wrappingKey, {
    List<int>? aad,
  }) async {
    final concatenation = base64Url.decode(wrappedKeyBase64);
    final secretBox = SecretBox.fromConcatenation(
      concatenation,
      nonceLength: _aesGcm.nonceLength,
      macLength: _aesGcm.macAlgorithm.macLength,
    );
    final clearBytes = await _aesGcm.decrypt(
      secretBox,
      secretKey: wrappingKey,
      aad: aad ?? const [],
    );
    return SecretKey(clearBytes);
  }

  /// Encrypts message [content] using a [key].
  ///
  /// Binds the encryption to [conversationId] and [messageId] via AAD.
  Future<String> encryptContent(
    String content,
    SecretKey key, {
    List<int>? aad,
  }) async {
    final secretBox = await _aesGcm.encrypt(
      utf8.encode(content),
      secretKey: key,
      aad: aad ?? const [],
    );
    return base64Url.encode(secretBox.concatenation());
  }

  /// Decrypts a [ciphertextBase64] string using a [key].
  Future<String> decryptContent(
    String ciphertextBase64,
    SecretKey key, {
    List<int>? aad,
  }) async {
    final concatenation = base64Url.decode(ciphertextBase64);
    final secretBox = SecretBox.fromConcatenation(
      concatenation,
      nonceLength: _aesGcm.nonceLength,
      macLength: _aesGcm.macAlgorithm.macLength,
    );
    final clearBytes = await _aesGcm.decrypt(
      secretBox,
      secretKey: key,
      aad: aad ?? const [],
    );
    return utf8.decode(clearBytes);
  }
}
