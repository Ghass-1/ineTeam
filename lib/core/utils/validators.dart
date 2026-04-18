import '../constants/app_constants.dart';

/// Form validation utilities.
class Validators {
  Validators._();

  /// Validates that email is not empty, well-formed, and ends with INPT domain.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final email = value.trim().toLowerCase();
    // Basic email format check
    final emailRegex = RegExp(r'^[\w\.\-]+@[\w\.\-]+\.\w+$');
    if (!emailRegex.hasMatch(email)) {
      return 'Enter a valid email address';
    }
    // INPT domain restriction
    if (!email.endsWith(AppInfo.allowedEmailDomain)) {
      return 'Only INPT emails (${AppInfo.allowedEmailDomain}) are allowed';
    }
    return null;
  }

  /// Validates password strength (min 6 chars).
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Validates that confirm password matches.
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Validates that a name is not empty.
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  /// Validates location field.
  static String? validateLocation(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Location is required';
    }
    return null;
  }

  /// Validates max players count.
  static String? validateMaxPlayers(int? value) {
    if (value == null || value < 2) {
      return 'At least 2 players required';
    }
    if (value > 30) {
      return 'Maximum 30 players allowed';
    }
    return null;
  }
}
