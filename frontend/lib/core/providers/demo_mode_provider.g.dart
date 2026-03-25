// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'demo_mode_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(isDemoMode)
final isDemoModeProvider = IsDemoModeProvider._();

final class IsDemoModeProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  IsDemoModeProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'isDemoModeProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$isDemoModeHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return isDemoMode(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$isDemoModeHash() => r'fd2746bae31212e33a9d8bf0d69fb8a545e9f349';
