// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recovery_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(recoveryService)
final recoveryServiceProvider = RecoveryServiceProvider._();

final class RecoveryServiceProvider
    extends
        $FunctionalProvider<RecoveryService, RecoveryService, RecoveryService>
    with $Provider<RecoveryService> {
  RecoveryServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recoveryServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recoveryServiceHash();

  @$internal
  @override
  $ProviderElement<RecoveryService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RecoveryService create(Ref ref) {
    return recoveryService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecoveryService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecoveryService>(value),
    );
  }
}

String _$recoveryServiceHash() => r'a357cd83e7d21112dd830a607c31186d8c118ce7';
