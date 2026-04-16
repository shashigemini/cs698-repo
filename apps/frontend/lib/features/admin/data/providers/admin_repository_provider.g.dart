// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the [AdminRepository] instance.

@ProviderFor(adminRepository)
final adminRepositoryProvider = AdminRepositoryProvider._();

/// Provides the [AdminRepository] instance.

final class AdminRepositoryProvider extends $FunctionalProvider<AdminRepository,
    AdminRepository, AdminRepository> with $Provider<AdminRepository> {
  /// Provides the [AdminRepository] instance.
  AdminRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'adminRepositoryProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$adminRepositoryHash();

  @$internal
  @override
  $ProviderElement<AdminRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AdminRepository create(Ref ref) {
    return adminRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AdminRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AdminRepository>(value),
    );
  }
}

String _$adminRepositoryHash() => r'b22cbf6b1da02e83499471e573de2b06d7d59057';
