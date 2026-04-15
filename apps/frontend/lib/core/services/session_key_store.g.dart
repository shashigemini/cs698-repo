// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_key_store.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// In-memory store for sensitive cryptographic keys during an active session.
///
/// This store holds the [AccountKey] and [LocalMasterKey] in memory so they
/// can be accessed by repositories without re-deriving them from the password.
/// All keys are cleared upon logout.

@ProviderFor(SessionKeyStore)
final sessionKeyStoreProvider = SessionKeyStoreProvider._();

/// In-memory store for sensitive cryptographic keys during an active session.
///
/// This store holds the [AccountKey] and [LocalMasterKey] in memory so they
/// can be accessed by repositories without re-deriving them from the password.
/// All keys are cleared upon logout.
final class SessionKeyStoreProvider
    extends $NotifierProvider<SessionKeyStore, SessionKeyState> {
  /// In-memory store for sensitive cryptographic keys during an active session.
  ///
  /// This store holds the [AccountKey] and [LocalMasterKey] in memory so they
  /// can be accessed by repositories without re-deriving them from the password.
  /// All keys are cleared upon logout.
  SessionKeyStoreProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'sessionKeyStoreProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$sessionKeyStoreHash();

  @$internal
  @override
  SessionKeyStore create() => SessionKeyStore();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SessionKeyState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SessionKeyState>(value),
    );
  }
}

String _$sessionKeyStoreHash() => r'480722990f7036243592cab67f4db2bbb4687550';

/// In-memory store for sensitive cryptographic keys during an active session.
///
/// This store holds the [AccountKey] and [LocalMasterKey] in memory so they
/// can be accessed by repositories without re-deriving them from the password.
/// All keys are cleared upon logout.

abstract class _$SessionKeyStore extends $Notifier<SessionKeyState> {
  SessionKeyState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<SessionKeyState, SessionKeyState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<SessionKeyState, SessionKeyState>,
        SessionKeyState,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
