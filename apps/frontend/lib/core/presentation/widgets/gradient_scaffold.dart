import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

/// A [Scaffold] wrapped in a gradient background.
///
/// Applies [AppTheme.backgroundGradient] behind a transparent
/// scaffold so screens get the branded purple-blue-teal gradient
/// without repeating boilerplate.
class GradientScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Widget? drawer;

  /// Creates a [GradientScaffold].
  const GradientScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.drawer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBar,
        body: body,
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
        drawer: drawer,
      ),
    );
  }
}
