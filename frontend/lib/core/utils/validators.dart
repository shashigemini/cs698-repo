/// Password strength classification.
enum PasswordStrength {
  /// Fewer than 8 characters.
  weak,

  /// Meets length but missing some character classes.
  medium,

  /// Meets all character-class requirements.
  strong,
}

/// Validation utilities for authentication forms.
///
/// Provides email format checking, password strength scoring,
/// and full password validation per DevSpec #3 requirements.
class Validators {
  static final RegExp _emailRegex = RegExp(
    r'^[\w\-\.\+]+@([\w\-]+\.)+[\w\-]{2,4}$',
  );

  /// Returns `null` if [email] is valid, or an error message.
  ///
  /// Validates against the pattern
  /// `^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$` and a 255-character
  /// maximum.
  static String? validateEmail(String email) {
    if (email.isEmpty) return 'Email is required';
    if (email.length > 255) return 'Email must be 255 characters or fewer';
    if (!_emailRegex.hasMatch(email)) return 'Enter a valid email address';
    return null;
  }

  /// Returns `null` if [password] passes all rules, or an
  /// error message describing the first failing rule.
  ///
  /// Rules: ≥ 8 characters, at least one uppercase letter,
  /// one lowercase letter, one digit, and one special character.
  static String? validatePassword(String password) {
    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain an uppercase letter';
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain a lowercase letter';
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain a digit';
    }
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain a special character';
    }
    return null;
  }

  /// Classifies [password] strength.
  ///
  /// - [PasswordStrength.weak]: fewer than 8 characters
  /// - [PasswordStrength.medium]: ≥ 8 chars, 2-3 classes met
  /// - [PasswordStrength.strong]: ≥ 8 chars, all 4 classes met
  static PasswordStrength passwordStrength(String password) {
    if (password.length < 8) return PasswordStrength.weak;

    var score = 0;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      score++;
    }

    if (score >= 4) return PasswordStrength.strong;
    if (score >= 2) return PasswordStrength.medium;
    return PasswordStrength.weak;
  }
}
