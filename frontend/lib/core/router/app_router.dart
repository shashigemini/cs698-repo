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
import '../../features/admin/presentation/admin_screen.dart';
import '../../features/admin/application/admin_controller.dart';

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
  final isInitialized = ref.watch(authInitializationProvider);

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
      final isAdminUser = ref.read(isAdminProvider);
      
      final uriStr = state.uri.toString();
      final isLoggingInOrRegistering = uriStr == '/login' || uriStr == '/register';
      final isOnStartup = uriStr == '/';
      final isTryingToAdmin = uriStr.startsWith('/admin');

      if (!isInitialized) {
        // Stay on startup until auth state is definitively known
        return isOnStartup ? null : '/';
      }

      if (isOnStartup && isLoggedIn) {
        AppLogger.d(
          'AppRouter: Redirecting logged-in user from startup to home',
        );
        return '/home';
      } else if (isOnStartup && !isLoggedIn) {
        // Once initialized and not logged in, go to login
        AppLogger.d(
          'AppRouter: Auth initialized, redirecting guest from startup to login',
        );
        return '/login';
      }

      if (!isLoggedIn && !isLoggingInOrRegistering) {
        AppLogger.d(
          'AppRouter: Redirecting unauthenticated user to login',
          error: {'destination': uriStr},
        );
        // Not logged in and accessing protected route -> Login
        return '/login';
      }

      if (isLoggedIn && isLoggingInOrRegistering) {
        AppLogger.d(
          'AppRouter: Redirecting logged-in user away from auth screen to home',
        );
        // Logged in and accessing login/register -> Home
        return '/home';
      }

      if (isLoggedIn && isTryingToAdmin && !isAdminUser) {
        AppLogger.w(
          'AppRouter: Unauthorized access attempt to admin panel',
        );
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const StartupScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const LoginScreen(initialLoginState: false),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminScreen(),
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
