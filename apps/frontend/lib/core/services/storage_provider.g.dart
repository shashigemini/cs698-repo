// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'storage_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the active [StorageService] implementation.
///
/// Returns [SecureStorageService] by default for production use.
/// Can be overridden in tests or development environments
/// to provide a mock implementation.

@ProviderFor(storageService)
final storageServiceProvider = StorageServiceProvider._();

/// Provides the active [StorageService] implementation.
///
/// Returns [SecureStorageService] by default for production use.
/// Can be overridden in tests or development environments
/// to provide a mock implementation.

final class StorageServiceProvider
    extends $FunctionalProvider<StorageService, StorageService, StorageService>
    with $Provider<StorageService> {
  /// Provides the active [StorageService] implementation.
  ///
  /// Returns [SecureStorageService] by default for production use.
  /// Can be overridden in tests or development environments
  /// to provide a mock implementation.
  StorageServiceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'storageServiceProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$storageServiceHash();

  @$internal
  @override
  $ProviderElement<StorageService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  StorageService create(Ref ref) {
    return storageService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StorageService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StorageService>(value),
    );
  }
}

String _$storageServiceHash() => r'280758106d0f76de11330197022d571bd55912b3';
