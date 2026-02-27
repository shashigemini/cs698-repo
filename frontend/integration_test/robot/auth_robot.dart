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
    await tester.ensureVisible(loginButton);
    await tester.tap(loginButton);
    await tester.pumpAndSettle();
  }

  Future<void> tapRegister() async {
    await tester.ensureVisible(registerButton);
    await tester.tap(registerButton);
    await tester.pumpAndSettle();
  }

  Future<void> tapGuestLogin() async {
    await tester.ensureVisible(guestButton);
    await tester.tap(guestButton);
    await tester.pumpAndSettle();
  }

  Future<void> switchToRegister() async {
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
}
