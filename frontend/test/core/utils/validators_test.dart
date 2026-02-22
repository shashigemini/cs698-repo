import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/utils/validators.dart';

void main() {
  group('Validators - Email', () {
    test('valid email returns null', () {
      expect(Validators.validateEmail('test@example.com'), isNull);
      expect(Validators.validateEmail('user.name+tag@domain.co.uk'), isNull);
    });

    test('invalid email returns error message', () {
      expect(Validators.validateEmail(''), 'Email is required');
      expect(
        Validators.validateEmail('invalid-email'),
        'Enter a valid email address',
      );
      expect(
        Validators.validateEmail('test@.com'),
        'Enter a valid email address',
      );
      expect(
        Validators.validateEmail('test@com'),
        'Enter a valid email address',
      );
    });

    test('email exceeding 255 characters returns error', () {
      final longEmail = '${'a' * 250}@example.com';
      expect(
        Validators.validateEmail(longEmail),
        'Email must be 255 characters or fewer',
      );
    });
  });

  group('Validators - Password', () {
    test('valid password returns null', () {
      expect(Validators.validatePassword('StrongP@ssw0rd!'), isNull);
    });

    test('invalid password returns error message', () {
      expect(
        Validators.validatePassword('short'),
        'Password must be at least 8 characters',
      );
      expect(
        Validators.validatePassword('alllowercase1!'),
        'Password must contain an uppercase letter',
      );
      expect(
        Validators.validatePassword('ALLUPPERCASE1!'),
        'Password must contain a lowercase letter',
      );
      expect(
        Validators.validatePassword('NoDigitsHere!'),
        'Password must contain a digit',
      );
      expect(
        Validators.validatePassword('NoSpecialChar123'),
        'Password must contain a special character',
      );
    });
  });

  group('Validators - Password Strength', () {
    test('weak passwords', () {
      expect(Validators.passwordStrength('short'), PasswordStrength.weak);
      expect(Validators.passwordStrength('alllower'), PasswordStrength.weak);
    });

    test('medium passwords', () {
      expect(Validators.passwordStrength('Lower123'), PasswordStrength.medium);
      expect(Validators.passwordStrength('UPPER!@#'), PasswordStrength.medium);
    });

    test('strong passwords', () {
      expect(
        Validators.passwordStrength('StrongP@ssw0rd!'),
        PasswordStrength.strong,
      );
    });
  });

  group('Validators - mapAuthError', () {
    test('maps common errors', () {
      expect(
        Validators.mapAuthError('INVALID_CREDENTIALS'),
        'Invalid email or password. Please try again.',
      );
      expect(
        Validators.mapAuthError('EMAIL_ALREADY_EXISTS'),
        'An account with this email already exists.',
      );
      expect(
        Validators.mapAuthError('TOKEN_EXPIRED'),
        'Your session has expired. Please sign in again.',
      );
      expect(
        Validators.mapAuthError('UNKNOWN_ERROR'),
        'Authentication failed. Please try again.',
      );
    });
  });
}
