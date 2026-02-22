import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:frontend/features/auth/presentation/login_screen.dart';
import 'package:frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:frontend/features/auth/data/providers/auth_provider.dart';

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
    ).thenThrow(Exception('Invalid credentials'));

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
    verify(
      () => mockAuthRepository.login('test@test.com', 'wrongpass'),
    ).called(1);
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

  testWidgets('Register successful calls repository method', (tester) async {
    when(
      () => mockAuthRepository.register(any(), any()),
    ).thenAnswer((_) async => {});

    await tester.pumpWidget(createSubject());

    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle();

    final emailField = find.byKey(const Key('register_email_field'));
    final passwordField = find.byKey(const Key('register_password_field'));

    await tester.enterText(emailField, 'newuser@test.com');
    await tester.enterText(passwordField, 'ValidPass1!');

    final registerButton = find.byKey(const Key('register_button'));
    await tester.ensureVisible(registerButton);
    await tester.tap(registerButton);
    await tester.pumpAndSettle();

    verify(
      () => mockAuthRepository.register('newuser@test.com', 'ValidPass1!'),
    ).called(1);
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
