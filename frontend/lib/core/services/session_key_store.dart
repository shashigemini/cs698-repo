import 'package:cryptography/cryptography.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'session_key_store.g.dart';

/// In-memory store for sensitive cryptographic keys during an active session.
///
/// This store holds the [AccountKey] and [LocalMasterKey] in memory so they
/// can be accessed by repositories without re-deriving them from the password.
/// All keys are cleared upon logout.
@riverpod
class SessionKeyStore extends _$SessionKeyStore {
  @override
  SessionKeyState build() {
    return const SessionKeyState();
  }

  /// Sets the [AccountKey].
  void setAccountKey(SecretKey key) {
    state = state.copyWith(accountKey: key);
  }

  /// Sets the [LocalMasterKey].
  void setMasterKey(SecretKey key) {
    state = state.copyWith(masterKey: key);
  }

  /// Clears all keys from memory.
  void clear() {
    state = const SessionKeyState();
  }

  /// Gets the current [AccountKey].
  SecretKey? get currentAccountKey => state.accountKey;

  /// Gets the current [LocalMasterKey].
  SecretKey? get currentMasterKey => state.masterKey;
}

/// State for [SessionKeyStore].
class SessionKeyState {
  final SecretKey? accountKey;
  final SecretKey? masterKey;

  const SessionKeyState({this.accountKey, this.masterKey});

  SessionKeyState copyWith({SecretKey? accountKey, SecretKey? masterKey}) {
    return SessionKeyState(
      accountKey: accountKey ?? this.accountKey,
      masterKey: masterKey ?? this.masterKey,
    );
  }
}
