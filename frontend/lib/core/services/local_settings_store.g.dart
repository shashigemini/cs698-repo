// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_settings_store.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the initialized [SharedPreferences] instance.
///
/// This provider must be overridden in the [ProviderScope] during app startup.

@ProviderFor(sharedPreferences)
final sharedPreferencesProvider = SharedPreferencesProvider._();

/// Provides the initialized [SharedPreferences] instance.
///
/// This provider must be overridden in the [ProviderScope] during app startup.

final class SharedPreferencesProvider extends $FunctionalProvider<
    SharedPreferences,
    SharedPreferences,
    SharedPreferences> with $Provider<SharedPreferences> {
  /// Provides the initialized [SharedPreferences] instance.
  ///
  /// This provider must be overridden in the [ProviderScope] during app startup.
  SharedPreferencesProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'sharedPreferencesProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$sharedPreferencesHash();

  @$internal
  @override
  $ProviderElement<SharedPreferences> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SharedPreferences create(Ref ref) {
    return sharedPreferences(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SharedPreferences value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SharedPreferences>(value),
    );
  }
}

String _$sharedPreferencesHash() => r'1c2dd1a84771b17e16cc7c9461dd6736a2a28921';

/// Provides the [LocalSettingsStore] instance.

@ProviderFor(localSettingsStore)
final localSettingsStoreProvider = LocalSettingsStoreProvider._();

/// Provides the [LocalSettingsStore] instance.

final class LocalSettingsStoreProvider extends $FunctionalProvider<
    LocalSettingsStore,
    LocalSettingsStore,
    LocalSettingsStore> with $Provider<LocalSettingsStore> {
  /// Provides the [LocalSettingsStore] instance.
  LocalSettingsStoreProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'localSettingsStoreProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$localSettingsStoreHash();

  @$internal
  @override
  $ProviderElement<LocalSettingsStore> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LocalSettingsStore create(Ref ref) {
    return localSettingsStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocalSettingsStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocalSettingsStore>(value),
    );
  }
}

String _$localSettingsStoreHash() =>
    r'1212d82a14d3d7bd955252628129d5ddf2749700';
