import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/presentation/widgets/glass_container.dart';
import 'widgets/mnemonic_display_dialog.dart';
import 'widgets/recover_account_dialog.dart';
import '../../../core/presentation/widgets/gradient_button.dart';
import '../../../core/presentation/widgets/gradient_scaffold.dart';
import '../../../core/utils/validators.dart';
import '../../../core/exceptions/app_exceptions.dart';
import '../../../theme/app_theme.dart';
import '../application/auth_controller.dart';

/// Login and registration screen.
///
/// Provides a tabbed interface that toggles between Login and
/// Register form. Also offers a "Continue as Guest" option.
class LoginScreen extends ConsumerStatefulWidget {
  /// Creates a [LoginScreen].
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLogin = true; // Toggle between Login and Register
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _handleAuth() async {
    final email = _isLogin
        ? _emailController.text
        : _registerEmailController.text;
    final password = _isLogin
        ? _passwordController.text
        : _registerPasswordController.text;

    final emailError = Validators.validateEmail(email);
    if (emailError != null) {
      _showError(emailError);
      return;
    }

    if (!_isLogin) {
      final passError = Validators.validatePassword(password);
      if (passError != null) {
        _showError(passError);
        return;
      }
    } else if (password.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await ref.read(authControllerProvider.notifier).login(email, password);
      } else {
        final mnemonic = await ref
            .read(authControllerProvider.notifier)
            .register(email, password);

        if (mounted) {
          debugPrint('UI: Register success, showing MnemonicDisplayDialog');
          await showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (context) => MnemonicDisplayDialog(mnemonic: mnemonic),
          );

          // After mnemonic is acknowledged, finalize registration to trigger redirect
          if (mounted) {
            await ref
                .read(authControllerProvider.notifier)
                .finalizeRegistration();
          }
        }
      }
      // Navigation handled by GoRouter redirect
    } catch (e) {
      if (mounted) {
        var message = e.toString();
        if (e is AppException) {
          message = e.message;
        } else if (e is DioException && e.error is AppException) {
          message = (e.error as AppException).message;
        }
        _showError(message);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _guestLogin() async {
    if (_isLoading) return; // Prevent multiple taps
    setState(() => _isLoading = true);
    try {
      await ref.read(authControllerProvider.notifier).loginAnonymously();
      // Navigation handled by GoRouter redirect
    } catch (e) {
      if (mounted) {
        var message = e.toString();
        if (e is AppException) {
          message = e.message;
        } else if (e is DioException && e.error is AppException) {
          message = (e.error as AppException).message;
        }
        _showError('Guest login failed: $message');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.purple100, AppTheme.blue50],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  LucideIcons.messageSquare,
                  size: 40,
                  color: AppTheme.teal500,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AppStrings.brandName,
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.gray900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.tagline,
                style: GoogleFonts.inter(fontSize: 16, color: AppTheme.gray700),
              ),
              const SizedBox(height: 48),

              // Auth Card
              GlassContainer(
                width: 400,
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Tabs
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.gray200.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          _LoginTab(
                            text: AppStrings.loginTab,
                            isSelected: _isLogin,
                            onTap: () => setState(() => _isLogin = true),
                          ),
                          _LoginTab(
                            text: AppStrings.registerTab,
                            isSelected: !_isLogin,
                            onTap: () => setState(() => _isLogin = false),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Inputs
                    if (_isLogin) ...[
                      _LoginTextField(
                        controller: _emailController,
                        label: AppStrings.emailLabel,
                        icon: LucideIcons.mail,
                        fieldKey: 'email_field',
                        obscureText: false,
                      ),
                      const SizedBox(height: 16),
                      _LoginTextField(
                        controller: _passwordController,
                        label: AppStrings.passwordLabel,
                        icon: LucideIcons.lock,
                        fieldKey: 'password_field',
                        obscureText: _obscurePassword,
                        isPassword: true,
                        onToggleObscure: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          key: const Key('forgot_password_button'),
                          onPressed: () {
                            showDialog<void>(
                              context: context,
                              builder: (context) =>
                                  const RecoverAccountDialog(),
                            );
                          },
                          child: Text(
                            AppStrings.forgotPassword,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.teal500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      _LoginTextField(
                        controller: _registerEmailController,
                        label: AppStrings.emailLabel,
                        icon: LucideIcons.mail,
                        fieldKey: 'register_email_field',
                        obscureText: false,
                      ),
                      const SizedBox(height: 16),
                      _LoginTextField(
                        controller: _registerPasswordController,
                        label: AppStrings.passwordLabel,
                        icon: LucideIcons.lock,
                        fieldKey: 'register_password_field',
                        obscureText: _obscurePassword,
                        isPassword: true,
                        onToggleObscure: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _registerPasswordController,
                        builder: (context, value, child) {
                          return _PasswordStrengthIndicator(
                            password: value.text,
                          );
                        },
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Action Button
                    GradientButton(
                      key: Key(_isLogin ? 'login_button' : 'register_button'),
                      text: _isLogin
                          ? AppStrings.loginTab
                          : AppStrings.createAccount,
                      onPressed: _isLoading ? null : _handleAuth,
                      isLoading: _isLoading,
                    ),

                    if (!_isLogin)
                      TextButton(
                        onPressed: () => setState(() => _isLogin = true),
                        child: Text(
                          AppStrings.alreadyHaveAccount,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.teal500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Divider
                    Row(
                      children: [
                        Expanded(child: Divider(color: AppTheme.gray200)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            AppStrings.orDivider,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.gray700,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: AppTheme.gray200)),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Guest Button
                    OutlinedButton(
                      onPressed: _isLoading ? null : _guestLogin,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppTheme.gray200),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        AppStrings.continueAsGuest,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.gray700,
                        ),
                      ),
                    ),

                    if (!_isLogin) ...[
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          AppStrings.guestQueryLimitLabel,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.gray700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A tab button in the Login/Register tab bar.
class _LoginTab extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _LoginTab({
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                    ),
                  ]
                : [],
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: isSelected ? AppTheme.gray900 : AppTheme.gray700,
            ),
          ),
        ),
      ),
    );
  }
}

/// A labelled text input used on the Login/Register form.
class _LoginTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? fieldKey;
  final bool isPassword;
  final bool obscureText;
  final VoidCallback? onToggleObscure;

  const _LoginTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.fieldKey,
    this.isPassword = false,
    required this.obscureText,
    this.onToggleObscure,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.gray700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          key: fieldKey != null ? Key(fieldKey!) : null,
          controller: controller,
          obscureText: isPassword && obscureText,
          style: GoogleFonts.inter(color: Colors.black),
          decoration: InputDecoration(
            hintText: isPassword ? '••••••••' : 'you@example.com',
            prefixIcon: Icon(icon, size: 20, color: AppTheme.gray700),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscureText ? LucideIcons.eye : LucideIcons.eyeOff,
                      size: 20,
                      color: AppTheme.gray700,
                    ),
                    onPressed: onToggleObscure,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

/// A password strength indicator widget for the registration tab.
class _PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const _PasswordStrengthIndicator({required this.password});

  @override
  Widget build(BuildContext context) {
    final strength = Validators.passwordStrength(password);
    Color color;
    String text;
    double widthFactor;

    switch (strength) {
      case PasswordStrength.weak:
        color = Colors.redAccent;
        text = 'Weak';
        widthFactor = 0.33;
        break;
      case PasswordStrength.medium:
        color = Colors.orangeAccent;
        text = 'Medium';
        widthFactor = 0.66;
        break;
      case PasswordStrength.strong:
        color = AppTheme.teal500;
        text = 'Strong';
        widthFactor = 1.0;
        break;
    }

    if (password.isEmpty) {
      color = AppTheme.gray200;
      text = '8+ chars, upper, lower, number, special';
      widthFactor = 0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Container(
                  height: 4,
                  width: constraints.maxWidth,
                  decoration: BoxDecoration(
                    color: AppTheme.gray200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 4,
                  width: constraints.maxWidth * widthFactor,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: password.isEmpty ? AppTheme.gray700 : color,
          ),
        ),
      ],
    );
  }
}
