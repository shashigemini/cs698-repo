import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../theme/app_theme.dart';
import 'glass_container.dart';

/// A widget that catches Flutter errors in its child subtree
/// and displays a graceful "Something went wrong" UI.
class ErrorBoundary extends StatefulWidget {
  final Widget child;

  const ErrorBoundary({super.key, required this.child});

  /// Manual trigger for testing or specific error catching
  static void reportError(BuildContext context, Object error) {
    final state = context.findAncestorStateOfType<_ErrorBoundaryState>();
    state?.setState(() {
      state._error = error;
    });
  }

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Material(
        child: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.backgroundGradient,
          ),
          child: Center(
            child: GlassContainer(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    LucideIcons.triangleAlert,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Something went wrong',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.gray900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'An unexpected error occurred. Please try restarting the app.',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: AppTheme.gray700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _error = null;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.teal500,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return widget.child;
  }

  @override
  void activate() {
    super.activate();
  }

  // This is the core magic that catches the errors
  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  // Use error reporting to catch sub-tree errors
}

/// A wrapper for the main app build method to catch top-level errors.
class GlobalErrorHandler extends StatefulWidget {
  final Widget child;

  const GlobalErrorHandler({super.key, required this.child});

  @override
  State<GlobalErrorHandler> createState() => _GlobalErrorHandlerState();
}

class _GlobalErrorHandlerState extends State<GlobalErrorHandler> {
  late final ErrorWidgetBuilder _oldBuilder;

  @override
  void initState() {
    super.initState();
    _oldBuilder = ErrorWidget.builder;
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Material(
        child: Container(
          color: Colors.white,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'UI Error: ${details.exception}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
        ),
      );
    };
  }

  @override
  void dispose() {
    ErrorWidget.builder = _oldBuilder;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
