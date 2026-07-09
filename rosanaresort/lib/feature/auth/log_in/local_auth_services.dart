import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
// تأكد من إضافة هذه المكتبة في pubspec.yaml وعمل import لها لدعم الـ iOS
import 'package:local_auth_darwin/local_auth_darwin.dart';

class LocalAuthService {
  final LocalAuthentication _auth;

  // Pattern Dependency Injection لسهولة عمل الـ Unit Testing لاحقاً
  LocalAuthService({LocalAuthentication? auth}) : _auth = auth ?? LocalAuthentication();

  /// التحقق مما إذا كان الجهاز يدعم الحماية الحيوية هاردوير وإذا كانت مفعلة من الإعدادات
  Future<bool> isBiometricAvailable() async {
    try {
      final canCheckBiometrics = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();

      print("canCheckBiometrics = $canCheckBiometrics");
      print("isDeviceSupported = $isSupported");

      final biometrics = await _auth.getAvailableBiometrics();
      print("Available biometrics = $biometrics");

      return canCheckBiometrics || isSupported;
    } on PlatformException catch (e) {
      print("Availability Error = ${e.code}");
      return false;
    }
  }

  /// تنفيذ عملية التحقق الحيوية (Face ID / Fingerprint)
  Future<bool> authenticate({
    required String localizedReason,
    required String localizedTitle,
    required String localizedCancelBtn,
  }) async {
    try {
      // التأكد أولاً من توفر الخدمة لتجنب انهيار التطبيق (Crash)
      if (!await isBiometricAvailable()) return false;

      return await _auth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
          useErrorDialogs: true,
        ),
        authMessages: <AuthMessages>[
          // إعدادات مخصصة لنظام أندرويد
          AndroidAuthMessages(
            signInTitle: localizedTitle,
            biometricHint: localizedReason,
            cancelButton: localizedCancelBtn,
          ),
          // إعدادات مخصصة لنظام iOS (تمت إضافتها)
          IOSAuthMessages(
            cancelButton: localizedCancelBtn,
            // يمكنك أيضاً إضافة localizedFallbackTitle إذا أردت تخصيص زر الـ PIN
          ),
        ],
      );
    } on PlatformException catch (e) {
      return _handlePlatformException(e);
    }
  }

  /// فحص الأخطاء الـ Native الخاصة بالنظام والتعامل معها برمجياً
  bool _handlePlatformException(PlatformException e) {
    // جميع هذه الأخطاء تعني فشل المصادقة أو عدم إمكانيتها، لذا يجب أن نرجع false
    switch (e.code) {
      case 'NotAvailable':
      case 'NotEnrolled':
      case 'LockedOut':
      case 'PermanentlyLockedOut':
      // يمكنك هنا طباعة الخطأ أو إرساله لخدمة تتبع الأخطاء (مثل Crashlytics)
        return false;
      default:
        return false;
    }
  }
}