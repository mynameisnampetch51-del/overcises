/// Form rules shared by the Login and Sign up screens.
/// Each returns an error message, or null when the value is fine.
abstract final class Validators {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static const minPasswordLength = 6;

  static String? name(String? value) {
    if ((value ?? '').trim().length < 2) return 'Enter your name';
    return null;
  }

  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Enter your email';
    if (!_email.hasMatch(email)) return 'Enter a valid email';
    return null;
  }

  static String? password(String? value) {
    if ((value ?? '').isEmpty) return 'Enter your password';
    if (value!.length < minPasswordLength) {
      return 'At least $minPasswordLength characters';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if ((value ?? '').isEmpty) return 'Confirm your password';
    if (value != password) return 'Passwords do not match';
    return null;
  }
}
