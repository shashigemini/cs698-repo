// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cryptography_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for [CryptographyService].

@ProviderFor(cryptographyService)
final cryptographyServiceProvider = CryptographyServiceProvider._();

/// Provider for [CryptographyService].

final class CryptographyServiceProvider extends $FunctionalProvider<
    CryptographyService,
    CryptographyService,
    CryptographyService> with $Provider<CryptographyService> {
  /// Provider for [CryptographyService].
  CryptographyServiceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'cryptographyServiceProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$cryptographyServiceHash();

  @$internal
  @override
  $ProviderElement<CryptographyService> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CryptographyService create(Ref ref) {
    return cryptographyService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CryptographyService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CryptographyService>(value),
    );
  }
}

String _$cryptographyServiceHash() =>
    r'd57ebcd734fa71d262b216cee699bfd6b2385ef3';
