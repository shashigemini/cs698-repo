// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'guest_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the [GuestService] instance.

@ProviderFor(guestService)
final guestServiceProvider = GuestServiceProvider._();

/// Provides the [GuestService] instance.

final class GuestServiceProvider
    extends $FunctionalProvider<GuestService, GuestService, GuestService>
    with $Provider<GuestService> {
  /// Provides the [GuestService] instance.
  GuestServiceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'guestServiceProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$guestServiceHash();

  @$internal
  @override
  $ProviderElement<GuestService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GuestService create(Ref ref) {
    return guestService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GuestService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GuestService>(value),
    );
  }
}

String _$guestServiceHash() => r'9b107f207ae64c47fbe1c2d2af1083c42c3a29a5';
