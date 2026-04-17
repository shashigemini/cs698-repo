import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:frontend/features/auth/presentation/login_screen.dart';
import 'package:frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:frontend/features/auth/data/providers/auth_provider.dart';
import 'package:frontend/core/exceptions/app_exceptions.dart';

// Mock the repository
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
  });

  Widget createSubject() {
    return ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(mockAuthRepository)],
      child: const MaterialApp(home: LoginScreen()),
    );
  }

  testWidgets('Login shows validation error if fields empty', (tester) async {
    await tester.pumpWidget(createSubject());

    final loginButton = find.byKey(const Key('login_button'));
    await tester.ensureVisible(loginButton);
    await tester.tap(loginButton);
    await tester.pump(); // Frame for SnackBar

    expect(find.text('Email is required'), findsOneWidget);
    verifyNever(() => mockAuthRepository.login(any(), any()));
  });

  testWidgets('Login shows error toast on invalid credentials', (tester) async {
    when(
      () => mockAuthRepository.login(any(), any()),
    ).thenThrow(const AuthException('Invalid email or password'));

    await tester.pumpWidget(createSubject());
    await tester.enterText(
      find.byKey(const Key('email_field')),
      'test@test.com',
    );
    await tester.enterText(
      find.byKey(const Key('password_field')),
      'wrongpass',
    );

    final loginBtn = find.byKey(const Key('login_button'));
    await tester.ensureVisible(loginBtn);
    await tester.tap(loginBtn);
    await tester.pumpAndSettle();

    expect(find.textContaining('Invalid email or password'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    verify(
      () => mockAuthRepository.login('test@test.com', 'wrongpass'),
    ).called(1);
  });

  testWidgets('Login shows timeout snackbar and clears loading', (tester) async {
    final hangingLoginCompleter = Completer<void>();
    when(() => mockAuthRepository.login(any(), any())).thenAnswer((_) async {
      await hangingLoginCompleter.future;
    });

    await tester.pumpWidget(createSubject());
    await tester.enterText(find.byKey(const Key('email_field')), 'test@test.com');
    await tester.enterText(find.byKey(const Key('password_field')), 'ValidPass1!');

    final loginBtn = find.byKey(const Key('login_button'));
    await tester.ensureVisible(loginBtn);
    await tester.tap(loginBtn);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(seconds: 21));
    await tester.pumpAndSettle();

    expect(
      find.text('Request timed out. Check backend/network and try again.'),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('Toggles between Login and Register tabs', (tester) async {
    await tester.pumpWidget(createSubject());

    expect(find.byKey(const Key('login_button')), findsOneWidget);
    expect(find.byKey(const Key('register_button')), findsNothing);

    // Tap Register tab
    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle();

    // Now showing Register form
    expect(find.byKey(const Key('register_button')), findsOneWidget);
    expect(find.byKey(const Key('login_button')), findsNothing);
  });

  testWidgets('Register shows validation error if password too short', (
    tester,
  ) async {
    await tester.pumpWidget(createSubject());

    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle();

    final emailField = find.byKey(const Key('register_email_field'));
    final passwordField = find.byKey(const Key('register_password_field'));

    await tester.enterText(emailField, 'newuser@test.com');
    await tester.enterText(passwordField, 'short'); // < 8 chars

    final registerButton = find.byKey(const Key('register_button'));
    await tester.ensureVisible(registerButton);
    await tester.tap(registerButton);
    await tester.pump(); // Frame for SnackBar

    expect(find.text('Password must be at least 8 characters'), findsOneWidget);
    verifyNever(() => mockAuthRepository.register(any(), any()));
  });

  testWidgets(
    'Register success shows mnemonic confirmation and finalizes registration',
    (tester) async {
    when(
      () => mockAuthRepository.register(any(), any()),
    ).thenAnswer((_) async => 'mock-mnemonic-phrase');
    when(() => mockAuthRepository.finalizeRegistration()).thenAnswer((_) async {});

    await tester.pumpWidget(createSubject());

    await tester.tap(find.text('Register'));
    // Wait for the tab AnimatedContainer (200ms) to finish
    await tester.pump(const Duration(milliseconds: 300));

    final emailField = find.byKey(const Key('register_email_field'));
    final passwordField = find.byKey(const Key('register_password_field'));

    await tester.enterText(emailField, 'newuser@test.com');
    await tester.enterText(passwordField, 'ValidPass1!');

    final registerButton = find.byKey(const Key('register_button'));
    await tester.ensureVisible(registerButton);
    await tester.tap(registerButton);
    // Wait for the async register Future and dialog open animation
    await tester.pump(); // Start the async call
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('mnemonic_confirm_button')), findsOneWidget);
    await tester.tap(find.byKey(const Key('mnemonic_confirm_button')));
    await tester.pumpAndSettle();

    verify(
      () => mockAuthRepository.register('newuser@test.com', 'ValidPass1!'),
    ).called(1);
    verify(() => mockAuthRepository.finalizeRegistration()).called(1);
  });

  testWidgets('Login exception clears loading indicator', (tester) async {
    when(
      () => mockAuthRepository.login(any(), any()),
    ).thenThrow(const AppNetworkException('No internet connection'));

    await tester.pumpWidget(createSubject());
    await tester.enterText(find.byKey(const Key('email_field')), 'test@test.com');
    await tester.enterText(find.byKey(const Key('password_field')), 'ValidPass1!');

    final loginBtn = find.byKey(const Key('login_button'));
    await tester.ensureVisible(loginBtn);
    await tester.tap(loginBtn);
    await tester.pumpAndSettle();

    expect(find.textContaining('No internet connection'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('Guest Login shows loading state', (tester) async {
    when(() => mockAuthRepository.loginAnonymously()).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(seconds: 1));
    });

    await tester.pumpWidget(createSubject());

    final guestButton = find.text('Continue as Guest');
    await tester.ensureVisible(guestButton);
    await tester.tap(guestButton);
    await tester.pump(); // Start animation/loading

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
  });
}
