import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../core/constants/app_strings.dart';
import 'widgets/mnemonic_display_dialog.dart';
import 'widgets/recover_account_dialog.dart';
import '../../../core/presentation/widgets/gradient_scaffold.dart';
import '../../../core/utils/validators.dart';
import '../../../core/exceptions/app_exceptions.dart';
import '../../../theme/app_theme.dart';
import '../application/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final bool initialLoginState;
  const LoginScreen({super.key, this.initialLoginState = true});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late bool _isLogin;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _isLogin = widget.initialLoginState;
  }

  Future<T?> _runWithLoadingGuard<T>(Future<T> Function() action) async {
    if (_isLoading) return null;
    setState(() => _isLoading = true);
    try {
      return await action().timeout(const Duration(seconds: 20));
    } on TimeoutException {
      if (mounted) { _showError('Request timed out. Check backend/network and try again.'); }
    } on AppException catch (e) {
      if (mounted) _showError(e.message);
    } on DioException catch (e) {
      if (!mounted) return null;
      if (e.error is AppException) {
        _showError((e.error as AppException).message);
        return null;
      }
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          _showError('Request timed out. Check backend/network and try again.');
          break;
        case DioExceptionType.connectionError:
          _showError('Unable to reach server. Check your network and try again.');
          break;
        default:
          _showError('Request failed. Please try again.');
      }
    } catch (_) {
      if (mounted) _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
    return null;
  }

  Future<void> _handleAuth() async {
    final email = _isLogin ? _emailController.text : _registerEmailController.text;
    final password = _isLogin ? _passwordController.text : _registerPasswordController.text;

    final emailError = Validators.validateEmail(email);
    if (emailError != null) { _showError(emailError); return; }

    if (!_isLogin) {
      final passError = Validators.validatePassword(password);
      if (passError != null) { _showError(passError); return; }
    } else if (password.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    if (_isLogin) {
      await _runWithLoadingGuard(
        () => ref.read(authControllerProvider.notifier).login(email, password),
      );
      return;
    }

    final mnemonic = await _runWithLoadingGuard<String>(
      () => ref.read(authControllerProvider.notifier).register(email, password),
    );
    if (mnemonic == null || !mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => MnemonicDisplayDialog(mnemonic: mnemonic),
    );

    if (mounted) {
      await _runWithLoadingGuard<void>(
        () => ref.read(authControllerProvider.notifier).finalizeRegistration(),
      );
    }
  }

  Future<void> _guestLogin() async {
    await _runWithLoadingGuard(
      () => ref.read(authControllerProvider.notifier).loginAnonymously(),
    );
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppTheme.inkDark : AppTheme.inkLight;
    final muted = isDark ? AppTheme.mutedDark : AppTheme.mutedLight;
    final surface = isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight;
    final border = isDark ? AppTheme.borderDark : AppTheme.borderLight;

    return GradientScaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Logo mark ──────────────────────────────────
              Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x334F46E5),
                      blurRadius: 30,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  LucideIcons.bookOpen,
                  size: 32,
                  color: Colors.white,
                  semanticLabel: AppStrings.a11yBrandLogo,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.brandName,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: ink,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'ask  ·  reflect  ·  become',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: muted,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 40),

              // ── Auth card ──────────────────────────────────
              _AuthCard(
                isDark: isDark,
                ink: ink,
                muted: muted,
                surface: surface,
                border: border,
                isLogin: _isLogin,
                isLoading: _isLoading,
                obscurePassword: _obscurePassword,
                emailController: _emailController,
                passwordController: _passwordController,
                registerEmailController: _registerEmailController,
                registerPasswordController: _registerPasswordController,
                onTabSwitch: (v) => setState(() => _isLogin = v),
                onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                onAuth: _handleAuth,
                onGuestLogin: _guestLogin,
                onForgotPassword: () => showDialog<void>(
                  context: context,
                  builder: (context) => const RecoverAccountDialog(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthCard extends StatelessWidget {
  final bool isDark;
  final Color ink;
  final Color muted;
  final Color surface;
  final Color border;
  final bool isLogin;
  final bool isLoading;
  final bool obscurePassword;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController registerEmailController;
  final TextEditingController registerPasswordController;
  final ValueChanged<bool> onTabSwitch;
  final VoidCallback onToggleObscure;
  final VoidCallback onAuth;
  final VoidCallback onGuestLogin;
  final VoidCallback onForgotPassword;

  const _AuthCard({
    required this.isDark,
    required this.ink,
    required this.muted,
    required this.surface,
    required this.border,
    required this.isLogin,
    required this.isLoading,
    required this.obscurePassword,
    required this.emailController,
    required this.passwordController,
    required this.registerEmailController,
    required this.registerPasswordController,
    required this.onTabSwitch,
    required this.onToggleObscure,
    required this.onAuth,
    required this.onGuestLogin,
    required this.onForgotPassword,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.06),
                blurRadius: 50,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tabs
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0x0AFFFFFF)
                      : const Color(0x0A0F172A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _Tab(
                      label: AppStrings.loginTab,
                      isSelected: isLogin,
                      isDark: isDark,
                      ink: ink,
                      muted: muted,
                      onTap: () => onTabSwitch(true),
                    ),
                    _Tab(
                      label: AppStrings.registerTab,
                      isSelected: !isLogin,
                      isDark: isDark,
                      ink: ink,
                      muted: muted,
                      onTap: () => onTabSwitch(false),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Fields
              if (isLogin) ...[
                _Field(
                  controller: emailController,
                  label: AppStrings.emailLabel,
                  icon: LucideIcons.mail,
                  hint: 'you@example.com',
                  obscure: false,
                  isDark: isDark,
                  ink: ink,
                  muted: muted,
                  border: border,
                  fieldKey: 'email_field',
                ),
                const SizedBox(height: 14),
                _Field(
                  controller: passwordController,
                  label: AppStrings.passwordLabel,
                  icon: LucideIcons.lock,
                  hint: '••••••••',
                  obscure: obscurePassword,
                  isPassword: true,
                  isDark: isDark,
                  ink: ink,
                  muted: muted,
                  border: border,
                  fieldKey: 'password_field',
                  onToggleObscure: onToggleObscure,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    key: const Key('forgot_password_button'),
                    onPressed: onForgotPassword,
                    child: Text(
                      AppStrings.forgotPassword,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.accentSoft,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                _Field(
                  controller: registerEmailController,
                  label: AppStrings.emailLabel,
                  icon: LucideIcons.mail,
                  hint: 'you@example.com',
                  obscure: false,
                  isDark: isDark,
                  ink: ink,
                  muted: muted,
                  border: border,
                  fieldKey: 'register_email_field',
                ),
                const SizedBox(height: 14),
                _Field(
                  controller: registerPasswordController,
                  label: AppStrings.passwordLabel,
                  icon: LucideIcons.lock,
                  hint: '••••••••',
                  obscure: obscurePassword,
                  isPassword: true,
                  isDark: isDark,
                  ink: ink,
                  muted: muted,
                  border: border,
                  fieldKey: 'register_password_field',
                  onToggleObscure: onToggleObscure,
                ),
                const SizedBox(height: 14),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: registerPasswordController,
                  builder: (context, value, _) =>
                      _PasswordStrengthBar(password: value.text),
                ),
              ],

              const SizedBox(height: 22),

              // Primary CTA
              _GradientButton(
                key: Key(isLogin ? 'login_button' : 'register_button'),
                label: isLogin ? 'Begin your practice' : AppStrings.createAccount,
                isLoading: isLoading,
                onPressed: isLoading ? null : onAuth,
              ),

              if (!isLogin)
                TextButton(
                  onPressed: () => onTabSwitch(true),
                  child: Text(
                    AppStrings.alreadyHaveAccount,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.accentSoft,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // Divider
              Row(
                children: [
                  Expanded(child: Divider(color: border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      AppStrings.orDivider,
                      style: GoogleFonts.inter(fontSize: 11, color: muted, letterSpacing: 1),
                    ),
                  ),
                  Expanded(child: Divider(color: border)),
                ],
              ),

              const SizedBox(height: 20),

              // Guest CTA
              GestureDetector(
                onTap: isLoading ? null : onGuestLogin,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: border),
                  ),
                  child: Text(
                    'Continue as guest · 5 questions',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: muted,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isDark;
  final Color ink;
  final Color muted;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.ink,
    required this.muted,
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
            color: isSelected
                ? (isDark ? const Color(0x14FFFFFF) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected && !isDark
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 13,
              color: isSelected ? ink : muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String hint;
  final bool obscure;
  final bool isPassword;
  final bool isDark;
  final Color ink;
  final Color muted;
  final Color border;
  final String? fieldKey;
  final VoidCallback? onToggleObscure;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    required this.hint,
    required this.obscure,
    required this.isDark,
    required this.ink,
    required this.muted,
    required this.border,
    this.isPassword = false,
    this.fieldKey,
    this.onToggleObscure,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: muted),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0x0AFFFFFF) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 14),
                child: Icon(icon, size: 16, color: muted),
              ),
              Expanded(
                child: TextField(
                  key: fieldKey != null ? Key(fieldKey!) : null,
                  controller: controller,
                  obscureText: isPassword && obscure,
                  style: GoogleFonts.inter(fontSize: 14, color: ink),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: GoogleFonts.inter(fontSize: 14, color: muted),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              if (isPassword)
                IconButton(
                  icon: Icon(
                    obscure ? LucideIcons.eye : LucideIcons.eyeOff,
                    size: 16,
                    color: muted,
                  ),
                  onPressed: onToggleObscure,
                  padding: const EdgeInsets.only(right: 8),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _GradientButton({
    super.key,
    required this.label,
    required this.isLoading,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          gradient: onPressed == null
              ? const LinearGradient(colors: [Colors.grey, Colors.grey])
              : AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: onPressed == null
              ? null
              : const [
                  BoxShadow(
                    color: Color(0x404F46E5),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ),
    );
  }
}

class _PasswordStrengthBar extends StatelessWidget {
  final String password;
  const _PasswordStrengthBar({required this.password});

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
        color = AppTheme.accentSoft;
        text = 'Strong';
        widthFactor = 1.0;
        break;
    }

    if (password.isEmpty) {
      color = AppTheme.borderLight;
      text = '8+ chars, upper, lower, number, special';
      widthFactor = 0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) => Stack(
            children: [
              Container(
                height: 4,
                width: constraints.maxWidth,
                decoration: BoxDecoration(
                  color: AppTheme.borderLight,
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
          ),
        ),
        const SizedBox(height: 6),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: password.isEmpty ? AppTheme.mutedLight : color,
          ),
        ),
      ],
    );
  }
}
