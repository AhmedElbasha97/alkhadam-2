import 'package:check_vpn_connection/check_vpn_connection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:safe_device/safe_device.dart';
import '../../../../config/routes/routes.dart';
import '../../../../core/cache/cache_keys.dart';
import '../../../../core/dependencies/app_dependencies.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/theme/transelation/localization_key.dart';
import '../../../../core/widgets/toast_widget.dart';
import '../../models/sign_in_model.dart';
import '../../otp/presentation/Otp_screen.dart';
import '../../services/auth_services.dart';
import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';

import '../local_auth_services.dart';
part 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final AuthServices _authServices;
   bool? checkForActivation = false;
  LoginCubit({required AuthServices authService})
      : _authServices = authService,
        super(const LoginState());

  // ── Toggle password visibility ───────────────────────────────────────────
  void togglePasswordVisibility() =>
      emit(state.copyWith(obscurePassword: !state.obscurePassword));

  // ── Verify Connection Safety (VPN Gating) ────────────────────────────────
  Future<void> automaticLogin(BuildContext context) async {
    final deps = AppDependencies.of(context);
    final userPhone = deps.cache.getData(key: CacheKeys.userPhoneNumber);
    final userNationalId = deps.cache.getData(key: CacheKeys.userNationalId);
    final checker = deps.cache.checkForData(key: CacheKeys.userPhoneNumber) &&
        deps.cache.checkForData(key: CacheKeys.userNationalId);
    checkForActivation = await _authServices.secuiretyChecker(context);
    // Safety Control Line A: Secure Connection State (VPN check)
    bool isConnectionSafe = await verifyConnectionSafety(context);
    if (!isConnectionSafe) {
      AppToast.error(context, TranslationKey.vpnToastError.tr());
      emit(state.copyWith(status: AuthStatus.failure));
      return;
    }

    // Safety Control Line B: Geo-location hardware verification
    Position? userPosition = await verifyAndFetchSecureLocation(context);
    if (userPosition == null) {
      emit(state.copyWith(status: AuthStatus.failure));
      return;
    }

    if (checker) {
      bool signinAuth = await LocalAuthService().authenticate(
        localizedReason: 'يرجى إثبات هويتك لتسجيل الدخول إلى حسابك تلقائياً',
        localizedTitle: 'تسجيل الدخول',
        localizedCancelBtn: 'إلغاء',
      );

      if (signinAuth) {
        final SignInModel? response = await _authServices.signingIn(
            "${userNationalId}", "${userPhone}", userPosition, userPosition, context);

        if (response?.status == "otp_sent") {
          final data = await _authServices.verifyResetPassOTP(
              "${userPhone}", "${response?.otp ?? 0}", userPosition);

          final savingOtp = await deps.cache
              .saveData(key: CacheKeys.savingUserId, value: data?.unit?.unId);

          if (savingOtp) {
            print("hiiiii 1");
            AppToast.success(
                context, TranslationKey.successfullyRequestForgetPass.tr());
            print("hiiiii 2");
            Navigator.of(context).pushNamed(
                Routes.passesScreen, arguments: data?.unit?.unId);
          }
        }
      } else {
        // 🔴 إظهار تنبيه بتصميم احترافي (High-Fidelity) لفتح الإعدادات
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
                backgroundColor: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.fingerprint_rounded,
                          size: 48,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 20),

                      const Text(
                        'تفعيل البصمة مطلوب',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 12),

                      Text(
                        'لتتمكن من تسجيل الدخول تلقائياً وبشكل آمن، يرجى تفعيل بصمة الإصبع أو الوجه من إعدادات الجهاز.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color
                              ?.withOpacity(0.7) ??
                              Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 28),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: BorderSide(color: Colors.grey.shade400),
                              ),
                              child: const Text(
                                'إلغاء',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                Navigator.of(context).pop();

                                if (Platform.isAndroid) {
                                  try {
                                    // فتح صفحة تسجيل البصمة مباشرة
                                    const AndroidIntent enrollIntent =
                                    AndroidIntent(
                                      action:
                                      'android.settings.BIOMETRIC_ENROLL',
                                    );

                                    await enrollIntent.launch();
                                  } catch (_) {
                                    try {
                                      // فتح إعدادات الأمان
                                      const AndroidIntent securityIntent =
                                      AndroidIntent(
                                        action:
                                        'android.settings.SECURITY_SETTINGS',
                                      );

                                      await securityIntent.launch();
                                    } catch (_) {
                                      // fallback
                                      await openAppSettings();
                                    }
                                  }
                                } else {
                                  await openAppSettings();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                              ),
                              child: const Text(
                                'الإعدادات',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
      }
    }
  }
  static Future<bool> verifyConnectionSafety(BuildContext context) async {
    try {
      bool isVpnActive = await CheckVpnConnection.isVpnActive();

      if (isVpnActive) {
        _showVpnRestrictedDialog(context);
        return false;
      }
      return true;
    } catch (e) {
      debugPrint("Error checking VPN status: $e");
      return true;
    }
  }

  static void _showVpnRestrictedDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return PopScope(
          canPop: false,
          child: Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.gpp_bad_rounded, color: Colors.redAccent, size: 42),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    TranslationKey.vpnAlertTitle.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    TranslationKey.vpnAlertContent.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF475569),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: Text(
                        TranslationKey.vpnRetryButton.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Verify & Request Geo-Location Access ─────────────────────────────────
  static Future<Position?> verifyAndFetchSecureLocation(BuildContext context, {bool? checkForActivation}) async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Run standard system capability checks
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showLocationRequiredDialog(context);
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showLocationRequiredDialog(context);
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showLocationRequiredDialog(context);
      return null;
    }
if(checkForActivation??true){
  // 2. FIRST DEFENSE LAYER: OS Subsystem Hardware Check (safe_device)
  try {
    bool isMockLocation = await SafeDevice.isMockLocation;
    bool isJailBroken = await SafeDevice.isJailBroken;
    bool isRealDevice = await SafeDevice.isRealDevice;

    // Block if fake location app is running, or device is compromised (rooted/jailbroken)
    if (isMockLocation || isJailBroken || (!isRealDevice && !isMockLocation)) {
      if (context.mounted) {
        _showFakeLocationWarningDialog(context);
      }
      return null; // Halt execution instantly
    }
  } catch (securityError) {
    debugPrint("Hardware security check bypass error: $securityError");
  }
}
    // 3. SECOND DEFENSE LAYER: GPS Payload Check (geolocator)
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Verify the coordinate data package itself hasn't been injected/mocked
      if (position.isMocked) {
        if (context.mounted) {
          _showFakeLocationWarningDialog(context);
        }
        return null;
      }

      return position; // Safe location verified completely
    } catch (e) {
      debugPrint("Failed fetching secure coordinates: $e");
      return null;
    }
  }

  // ─── FUNCTION 2: HIGH-SECURITY SPOOFED WARNING DIALOG ───────────────────
  static void _showFakeLocationWarningDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // User cannot dismiss by tapping outside
      builder: (BuildContext dialogContext) {
        return PopScope(
          canPop: false, // Disables system back button bypass
          child: Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.security_update_warning_rounded,
                      color: Colors.redAccent,
                      size: 42,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    TranslationKey.fakeLocationTitle.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    TranslationKey.fakeLocationContent.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF475569),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        // Re-trigger scanning loop to verify if user disabled fake GPS app
                        verifyAndFetchSecureLocation(context);
                      },
                      child: Text(
                        TranslationKey.retryButton.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  static void _showLocationRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return PopScope(
          canPop: false,
          child: Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_off_rounded, color: Colors.amber, size: 42),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    TranslationKey.locationAlertTitle.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    TranslationKey.locationAlertContent.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF475569),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () async {
                        Navigator.of(dialogContext).pop();
                        await Geolocator.openAppSettings();
                      },
                      child: Text(
                        TranslationKey.openSettingsButton.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  String maskPhoneNumber(String phone) {
    // 1. Strip out any spaces, dashes, or parentheses
    final cleaned = phone.replaceAll(RegExp(r'[\s\-()]+'), '');

    // 2. If it's too short to mask properly, return it as-is
    if (cleaned.length < 8) return phone;

    // 3. Keep the first 3 or 4 digits visible (handles country codes nicely)
    final int visiblePrefixLength = cleaned.startsWith('+') ? 4 : 3;
    final String prefix = cleaned.substring(0, visiblePrefixLength);

    // 4. Keep the last 2 digits visible for user recognition
    final String suffix = cleaned.substring(cleaned.length - 2);

    // 5. Create a dynamic mask for whatever length is in the middle
    final int maskLength = cleaned.length - visiblePrefixLength - 2;
    final String mask = '*' * maskLength;

    return '$prefix$mask$suffix';
  }
  // ── Login with Gated Controls ────────────────────────────────────────────
  Future<void> login({
    required String email,
    required String password,
    required BuildContext context
  }) async {
    emit(state.copyWith(status: AuthStatus.loading));
    if(checkForActivation??true) {
      // Safety Control Line A: Secure Connection State (VPN check)
      bool isConnectionSafe = await verifyConnectionSafety(context);
      if (!isConnectionSafe) {
        AppToast.error(context, TranslationKey.vpnToastError.tr());
        emit(state.copyWith(status: AuthStatus.failure));
        return;
      }
    }
      // Safety Control Line B: Geo-location hardware verification
      Position? userPosition = await verifyAndFetchSecureLocation(context, checkForActivation: checkForActivation);
      if (userPosition == null) {
        emit(state.copyWith(status: AuthStatus.failure));
        return;
      }

    try {
      final SignInModel? response = await _authServices.signingIn(email, password,userPosition,userPosition,context);

      if (response?.status == "otp_sent") {
        final deps = AppDependencies.of(context);
        deps.cache.saveData(key: CacheKeys.otpCode, value: response?.otp);
        deps.cache.saveData(key: CacheKeys.isRegisterAndNotVerified, value: true);
        deps.cache.saveData(key: CacheKeys.userPhoneNumber, value: password);
        deps.cache.saveData(key: CacheKeys.userNationalId, value: email);

        AppToast.success(context, "${TranslationKey.succeedInSigningIn.tr()} ");


        Navigator.of(context).pushNamed(
            Routes.otpPage,
            arguments: OtpPageArgs(
                email: password, maskedEmail: maskPhoneNumber(password),isComingFromSigningUp: true)
        );

        emit(state.copyWith(status: AuthStatus.success));
      } else {
        AppToast.error(context, _mapError(response?.message ?? ""));
        emit(state.copyWith(
          status: AuthStatus.failure,
          errorMessage: _mapError(response?.message ?? ""),
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: _mapError(e.toString().toLowerCase()),
      ));
    }
  }

  void reset() => emit(const LoginState());

  String _mapError(String? e) {
    final msg = e ?? "";
    if (msg.contains('invalid') || msg.contains('401')) {
      return TranslationKey.wrongCredentials.tr();
    }
    if (msg.contains('network') || msg.contains('socket')) {
      return TranslationKey.checkYourInternet.tr();
    }
    return TranslationKey.tryAgainLater.tr();
  }
}