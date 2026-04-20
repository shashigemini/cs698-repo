import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class AuthRobot {
  final WidgetTester tester;

  AuthRobot(this.tester);

  // Finders
  Finder get emailField => find.byKey(const Key('email_field'));
  Finder get passwordField => find.byKey(const Key('password_field'));
  Finder get registerEmailField =>
      find.byKey(const Key('register_email_field'));
  Finder get registerPasswordField =>
      find.byKey(const Key('register_password_field'));
  Finder get loginButton => find.byKey(const Key('login_button'));
  Finder get registerButton => find.byKey(const Key('register_button'));
  Finder get guestButton => find.text('Continue as Guest');
  Finder get loginTab => find.text('Login');
  Finder get registerTab => find.text('Register');
  Finder get forgotPasswordButton =>
      find.byKey(const Key('forgot_password_button'));

  // Mnemonic Dialog
  Finder get mnemonicConfirmButton =>
      find.byKey(const Key('mnemonic_confirm_button'));

  // Recovery Dialog
  Finder get recoveryEmailField =>
      find.byKey(const Key('recovery_email_field'));
  Finder get recoveryMnemonicField =>
      find.byKey(const Key('recovery_mnemonic_field'));
  Finder get recoveryNewPasswordField =>
      find.byKey(const Key('recovery_new_password_field'));
  Finder get recoverySubmitButton =>
      find.byKey(const Key('recovery_submit_button'));

  // Actions
  Future<void> enterEmail(String email) async {
    await tester.enterText(emailField, email);
    await tester.pumpAndSettle();
  }

  Future<void> enterPassword(String password) async {
    await tester.enterText(passwordField, password);
    await tester.pumpAndSettle();
  }

  Future<void> enterRegisterEmail(String email) async {
    await tester.enterText(registerEmailField, email);
    await tester.pumpAndSettle();
  }

  Future<void> enterRegisterPassword(String password) async {
    await tester.enterText(registerPasswordField, password);
    await tester.pumpAndSettle();
  }

  Future<void> tapLogin() async {
    debugPrint('Robot: Tapping Login button');
    await tester.ensureVisible(loginButton);
    await tester.tap(loginButton);
    // Use manual pump instead of pumpAndSettle for loading animations
    await tester.pump(const Duration(milliseconds: 1000));
  }

  Future<void> tapRegister() async {
    debugPrint('Robot: Tapping Register button');
    await tester.ensureVisible(registerButton);
    await tester.tap(registerButton);
    // We use a manual pump here because registration triggers a dialog
    // and Windows/Linux often hangs on pumpAndSettle during dialog animations.
    await tester.pump(const Duration(milliseconds: 2000));
  }

  Future<void> tapGuestLogin() async {
    debugPrint('Robot: Tapping Guest Login button');
    await tester.ensureVisible(guestButton);
    await tester.tap(guestButton);
    await tester.pumpAndSettle();
  }

  Future<void> switchToRegister() async {
    debugPrint('Robot: Switching to Register tab');
    await tester.tap(registerTab);
    await tester.pumpAndSettle();
  }

  Future<void> switchToLogin() async {
    await tester.tap(loginTab);
    await tester.pumpAndSettle();
  }

  Future<void> login(String email, String password) async {
    await enterEmail(email);
    await enterPassword(password);
    await tapLogin();
  }

  Future<void> tapForgotPassword() async {
    await tester.tap(forgotPasswordButton);
    await tester.pumpAndSettle();
  }

  Future<void> confirmMnemonic() async {
    await tester.ensureVisible(mnemonicConfirmButton);
    await tester.tap(mnemonicConfirmButton);
    // Explicitly avoid pumpAndSettle here as it redirects to Home
    await tester.pump(const Duration(milliseconds: 1500));
  }

  Future<void> recoverAccount({
    required String email,
    required String mnemonic,
    required String newPassword,
  }) async {
    debugPrint('Robot: Entering recovery details');
    await tester.enterText(recoveryEmailField, email);
    await tester.pumpAndSettle();
    await tester.enterText(recoveryMnemonicField, mnemonic);
    await tester.pumpAndSettle();
    await tester.enterText(recoveryNewPasswordField, newPassword);
    await tester.pumpAndSettle();

    debugPrint('Robot: Tapping Reset Password button');
    await tester.tap(recoverySubmitButton);
    // Explicitly avoid pumpAndSettle here as it auto-logins to Home
    await tester.pump(const Duration(milliseconds: 2000));
  }
}
