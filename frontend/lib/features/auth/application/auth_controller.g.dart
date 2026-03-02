// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

String _$authControllerHash() => r'03a0bec934879284598e44fc0ece745e4a9a9483';

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
