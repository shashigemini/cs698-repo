import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../utils/app_logger.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/startup/presentation/startup_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';

part 'app_router.g.dart';

/// Provides the application [GoRouter] with auth-aware
/// redirects.
///
/// Watches [authControllerProvider] and redirects
/// unauthenticated users to `/login` and authenticated users
/// away from the login page.
@riverpod
GoRouter goRouter(Ref ref) {
  final authState = ref.watch(authControllerProvider);

  // Note: For riverpod_generator AsyncNotifiers, if we want to trigger a refresh
  // on every stream emission, we can either use ref.listen on the provider itself,
  // or rely on the fact that `ref.watch(authControllerProvider)` will automatically
  // rebuild this entire provider (and thus the GoRouter) when the auth state changes.
  // Rebuilding the GoRouter is generally fine in modern GoRouter versions,
  // but if it loses state, we should use a Listenable adapter.
  // Since `authState` causes a rebuild, GoRouter takes the new redirect logic.

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authState != null;
      final isLoggingIn = state.uri.toString() == '/login';
      final isOnStartup = state.uri.toString() == '/';

      if (isOnStartup && isLoggedIn) {
        AppLogger.d(
          'AppRouter: Redirecting logged-in user from startup to home',
        );
        return '/home';
      } else if (isOnStartup && !isLoggedIn) {
        // Stay on startup until StartupScreen navigates
        return null;
      }

      if (!isLoggedIn && !isLoggingIn) {
        AppLogger.d(
          'AppRouter: Redirecting unauthenticated user to login',
          error: {'destination': state.uri.toString()},
        );
        // Not logged in and accessing protected route -> Login
        return '/login';
      }

      if (isLoggedIn && isLoggingIn) {
        AppLogger.d(
          'AppRouter: Redirecting logged-in user away from login to home',
        );
        // Logged in and accessing login -> Home
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const StartupScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}

/// Converts a [Stream] into a [ChangeNotifier] so that
/// [GoRouter.refreshListenable] can react to stream events.
class GoRouterRefreshStream extends ChangeNotifier {
  /// Creates a [GoRouterRefreshStream] that listens to [stream].
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
