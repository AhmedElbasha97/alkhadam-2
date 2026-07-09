import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/transelation/localization_key.dart';

/// Centralized validation for auth forms. Use in login, sign-up, and OTP flows.
class AuthValidation {
  AuthValidation._();

  // ─── Messages Getters (Ensures clean live-locale swapping) ──────────────────

  static String get requiredEmail => TranslationKey.enterEmail.tr();
  static String get invalidEmail => TranslationKey.invalidEmail.tr();
  static String get requiredPassword => TranslationKey.enterPassword.tr();
  static String get passwordMinLength => TranslationKey.passwordMinLength.tr();
  static String get requiredConfirmPassword => TranslationKey.confirmPassword.tr();
  static String get passwordsDoNotMatch => TranslationKey.passwordsDoNotMatch.tr();
  static String get requiredName => TranslationKey.enterName.tr();
  static String get requiredFirstName => TranslationKey.enterFirstName.tr();
  static String get requiredLastName => TranslationKey.enterLastName.tr();
  static String get requiredPhone => TranslationKey.enterPhone.tr();
  static String get invalidPhone => TranslationKey.invalidPhone.tr();

  // New Localization Hook Definitions
  static String get requiredNationalId => TranslationKey.requiredNationalId.tr();
  static String get invalidNationalId => TranslationKey.invalidNationalId.tr();
  static String get requiredEgyPhone => TranslationKey.requiredEgyPhone.tr();
  static String get invalidEgyPhone => TranslationKey.invalidEgyPhone.tr();
  static String get requiredLoginPassword => TranslationKey.requiredLoginPassword.tr();

  // ── Full Name ─────────────────────────────────────────────────────────────
  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return requiredName;
    }
    return null;
  }

  // ── Email ─────────────────────────────────────────────────────────────────
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return requiredEmail;
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return invalidEmail;
    }
    return null;
  }

  // ── Phone (Global General) ────────────────────────────────────────────────
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return requiredPhone;
    }
    final phoneRegex = RegExp(r'^\+?[0-9]{8,15}$');
    final cleaned = value.replaceAll(' ', '');
    if (!phoneRegex.hasMatch(cleaned)) {
      return invalidPhone;
    }
    return null;
  }

  // ── Egyptian Phone Number Validation ──────────────────────────────────────
  static String? validateEgyptianPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return requiredEgyPhone;
    }

    // Clean spaces, hyphens, and strip out Egyptian country codes (+2 or 2) if passed
    String cleaned = value.replaceAll(RegExp(r'[\s\-()]+'), '');
    if (cleaned.startsWith('+20')) {
      cleaned = cleaned.substring(3);
    } else if (cleaned.startsWith('20') && cleaned.length > 10) {
      cleaned = cleaned.substring(2);
    }

    // RegEx checks for standard 11 digits starting with 010, 011, 012, or 015
    final egyPhoneRegex = RegExp(r'^01[0125][0-9]{8}$');
    if (!egyPhoneRegex.hasMatch(cleaned)) {
      return invalidEgyPhone;
    }
    return null;
  }

  // ── Egyptian National ID Validation ───────────────────────────────────────
  static String? validateEgyptianNationalId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return requiredNationalId;
    }

    final cleaned = value.trim();
    // Must be exactly 14 digits long
    final nationalIdRegex = RegExp(r'^[0-9]{14}$');
    if (!nationalIdRegex.hasMatch(cleaned)) {
      return invalidNationalId;
    }

    // Advanced mathematical validation based on Egyptian government standards
    final int centuryDigit = int.parse(cleaned[0]);
    if (centuryDigit != 2 && centuryDigit != 3) {
      return invalidNationalId; // Only allows years between 1900-1999 (2) or 2000-2099 (3)
    }

    final int month = int.parse(cleaned.substring(3, 5));
    final int day = int.parse(cleaned.substring(5, 7));
    if (month < 1 || month > 12 || day < 1 || day > 31) {
      return invalidNationalId; // Catches fake logical calendar structures
    }

    return null;
  }

  // ── Password (login) ──────────────────────────────────────────────────────
  static String? validateLoginPassword(String? value) {
    if (value == null || value.isEmpty) {
      return requiredLoginPassword;
    }
    return null;
  }

  // ── Confirm Password ──────────────────────────────────────────────────────
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return requiredConfirmPassword;
    }
    if (value != password) {
      return passwordsDoNotMatch;
    }
    return null;
  }

  /// Simple password validation — required + minimum 8 characters only.
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return requiredPassword;
    if (value.length < 8) return passwordMinLength;
    return null;
  }

  static String? validateRequired(
      String? value, [
        String? message,
      ]) {
    if (message?.isEmpty ?? true) {
      message = TranslationKey.fieldRequired.tr();
    }
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  static String? validateName(String? value) {
    return validateRequired(value, requiredFirstName);
  }

  /// Identifier: email or phone for login
  static String? validateLoginIdentifier(String? value) {
    if (value == null || value.trim().isEmpty) return requiredEmail;
    if (value.contains('@')) return validateEmail(value);

    // Automatically switches parsing rules to fallback down to localized phone checks if no @ symbol is detected
    return validatePhone(value);
  }
}