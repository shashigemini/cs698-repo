import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/presentation/widgets/gradient_scaffold.dart';
import '../../../theme/app_theme.dart';

/// Splash screen displayed on app launch.
///
/// Shows the app logo, title, tagline, and a loading indicator.
/// After a 2-second delay it navigates to `/home`, relying
/// on [GoRouter] redirects to enforce authentication.
class StartupScreen extends StatefulWidget {
  /// Creates a [StartupScreen].
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  @override
  void initState() {
    super.initState();
    // Simulate initialization / token check
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        // Try to access Home. Router will redirect to Login if unauthenticated.
        // This ensures fully testing the redirect logic.
        context.go('/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon / Logo Placeholder
            Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.teal500.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.message,
                    size: 48,
                    color: AppTheme.teal500,
                  ),
                )
                .animate()
                .scale(duration: 600.ms, curve: Curves.easeOutBack)
                .fadeIn(duration: 600.ms),

            const SizedBox(height: 32),

            // Title
            Text(
                  AppStrings.brandName,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.gray900,
                  ),
                )
                .animate()
                .fadeIn(delay: 300.ms, duration: 600.ms)
                .moveY(begin: 20, end: 0, delay: 300.ms, curve: Curves.easeOut),

            const SizedBox(height: 12),

            // Tagline
            Text(
              AppStrings.tagline,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppTheme.gray700),
            ).animate().fadeIn(delay: 500.ms, duration: 600.ms),

            const SizedBox(height: 48),

            // Loading Indicator
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                backgroundColor: Colors.white.withValues(alpha: 0.5),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.teal500,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
            ).animate().fadeIn(delay: 800.ms, duration: 600.ms),
          ],
        ),
      ),
    );
  }
}
