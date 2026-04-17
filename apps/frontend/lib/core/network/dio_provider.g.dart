// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dio_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides a configured [Dio] instance for network requests.
///
/// This provider ensures that the network client is a singleton
/// tied to the Riverpod lifecycle, injected with the [StorageService]
/// and [HttpInterceptor] for automatic token management.

@ProviderFor(dio)
final dioProvider = DioProvider._();

/// Provides a configured [Dio] instance for network requests.
///
/// This provider ensures that the network client is a singleton
/// tied to the Riverpod lifecycle, injected with the [StorageService]
/// and [HttpInterceptor] for automatic token management.

final class DioProvider extends $FunctionalProvider<Dio, Dio, Dio>
    with $Provider<Dio> {
  /// Provides a configured [Dio] instance for network requests.
  ///
  /// This provider ensures that the network client is a singleton
  /// tied to the Riverpod lifecycle, injected with the [StorageService]
  /// and [HttpInterceptor] for automatic token management.
  DioProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dioProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dioHash();

  @$internal
  @override
  $ProviderElement<Dio> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Dio create(Ref ref) {
    return dio(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Dio value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Dio>(value),
    );
  }
}

String _$dioHash() => r'b07b6d78b4d5a7449148a5b53d402fb0afa705b7';
