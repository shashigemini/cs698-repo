// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the application [GoRouter] with auth-aware
/// redirects.
///
/// Watches [authControllerProvider] and redirects
/// unauthenticated users to `/login` and authenticated users
/// away from the login page.

@ProviderFor(goRouter)
final goRouterProvider = GoRouterProvider._();

/// Provides the application [GoRouter] with auth-aware
/// redirects.
///
/// Watches [authControllerProvider] and redirects
/// unauthenticated users to `/login` and authenticated users
/// away from the login page.

final class GoRouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
  /// Provides the application [GoRouter] with auth-aware
  /// redirects.
  ///
  /// Watches [authControllerProvider] and redirects
  /// unauthenticated users to `/login` and authenticated users
  /// away from the login page.
  GoRouterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'goRouterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$goRouterHash();

  @$internal
  @override
  $ProviderElement<GoRouter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoRouter create(Ref ref) {
    return goRouter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoRouter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoRouter>(value),
    );
  }
}

String _$goRouterHash() => r'91da49f0d79db226db19048b81b5037d532be75c';
