// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Indicates whether the initial auth token check has completed.
/// This prevents the [GoRouter] from prematurely redirecting to `/login`
/// while tokens are still being loaded from secure storage.

@ProviderFor(AuthInitialization)
final authInitializationProvider = AuthInitializationProvider._();

/// Indicates whether the initial auth token check has completed.
/// This prevents the [GoRouter] from prematurely redirecting to `/login`
/// while tokens are still being loaded from secure storage.
final class AuthInitializationProvider
    extends $NotifierProvider<AuthInitialization, bool> {
  /// Indicates whether the initial auth token check has completed.
  /// This prevents the [GoRouter] from prematurely redirecting to `/login`
  /// while tokens are still being loaded from secure storage.
  AuthInitializationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authInitializationProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authInitializationHash();

  @$internal
  @override
  AuthInitialization create() => AuthInitialization();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$authInitializationHash() =>
    r'c355cfb47db2c955d4dc19925a1f8f6e590fcbd3';

/// Indicates whether the initial auth token check has completed.
/// This prevents the [GoRouter] from prematurely redirecting to `/login`
/// while tokens are still being loaded from secure storage.

abstract class _$AuthInitialization extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Manages the authentication state of the application.
///
/// Converts the stream of auth state changes from the repository into
/// Riverpod state, and exposes authentication actions to the UI.

@ProviderFor(AuthController)
final authControllerProvider = AuthControllerProvider._();

/// Manages the authentication state of the application.
///
/// Converts the stream of auth state changes from the repository into
/// Riverpod state, and exposes authentication actions to the UI.
final class AuthControllerProvider
    extends $NotifierProvider<AuthController, String?> {
  /// Manages the authentication state of the application.
  ///
  /// Converts the stream of auth state changes from the repository into
  /// Riverpod state, and exposes authentication actions to the UI.
  AuthControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authControllerHash();

  @$internal
  @override
  AuthController create() => AuthController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$authControllerHash() => r'2b24975fee0f7f27cb9d776befe159f465e5bbe3';

/// Manages the authentication state of the application.
///
/// Converts the stream of auth state changes from the repository into
/// Riverpod state, and exposes authentication actions to the UI.

abstract class _$AuthController extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
