import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ── Added Security Imports ──────────────────────────────────────────────────
import 'package:check_vpn_connection/check_vpn_connection.dart';
import 'package:geolocator/geolocator.dart';
import 'package:safe_device/safe_device.dart';

import '../../../../config/routes/routes.dart';
import '../../../../core/cache/cache_keys.dart';
import '../../../../core/dependencies/app_dependencies.dart';
import '../../../../core/theme/transelation/localization_key.dart';
import '../../../../core/widgets/toast_widget.dart';
import '../../services/auth_services.dart';

part 'otp_state.dart';

class OtpCubit extends Cubit<OtpState> {
  final AuthServices _authServices;
  Timer? _countdownTimer;

  OtpCubit({
    required AuthServices authServices,
    int otpLength = 6,
  })  : _authServices = authServices,
        super(OtpState(
        otpLength: otpLength,
        digits: List.filled(otpLength, ''),
      )) {
    _startCountdown();
  }

  void updateDigit(int index, String value) {
    if (index < 0 || index >= state.otpLength) return;
    final newDigits = List<String>.from(state.digits);
    newDigits[index] = value;
    emit(state.copyWith(
      digits: newDigits,
      status: state.isFailure ? OtpStatus.initial : null,
      errorMessage: null,
    ));
  }

  void clearDigit(int index) {
    if (index < 0 || index >= state.otpLength) return;
    final newDigits = List<String>.from(state.digits);
    newDigits[index] = '';
    emit(state.copyWith(digits: newDigits));
  }

  void pasteOtp(String pasted) {
    final cleaned = pasted.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length < state.otpLength) return;
    final digits = cleaned
        .substring(0, state.otpLength)
        .split('')
        .map((e) => e)
        .toList();
    emit(state.copyWith(digits: digits));
  }

  // ── Enhanced Security Dialogs ─────────────────────────────────────────────

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

  static Future<Position?> verifyAndFetchSecureLocation(BuildContext context) async {
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


  // ── Verify OTP (Forget Password) ──────────────────────────────────────────
  Future<void> verifyForForgetPass(String email, BuildContext context) async {
    if (!state.isFilled) return;
    emit(state.copyWith(status: OtpStatus.loading, errorMessage: null));

    // Security Gate 1: VPN Check
    bool isConnectionSafe = await verifyConnectionSafety(context);
    if (!isConnectionSafe) {
      emit(state.copyWith(
        status: OtpStatus.failure,
        digits: List.filled(state.otpLength, ''),
      ));
      return;
    }

    // Security Gate 2: Location Check
    Position? userPosition = await verifyAndFetchSecureLocation(context);
    if (userPosition == null) {
      emit(state.copyWith(
        status: OtpStatus.failure,
        digits: List.filled(state.otpLength, ''),
      ));
      return;
    }

    try {
      final response = await _authServices.verifyResetPassOTP(email, state.digits.join(),userPosition);
      if (response?.status == "success") {
        final deps = AppDependencies.of(context);

        final savingOtp = await deps.cache.saveData(key: CacheKeys.savingUserId, value:response?.unit?.unId);

        if ( savingOtp) {

          print("hiiiii 1");
          AppToast.success(context, TranslationKey.successfullyRequestForgetPass.tr());
          print("hiiiii 2");
          Navigator.of(context).pushNamed(Routes.passesScreen,arguments: response?.unit?.unId);
          deps.cache.saveData(
              key: CacheKeys.isRegisterAndNotVerified,value: false) ?? false;
          print("hiiiii 3");
          emit(state.copyWith(status: OtpStatus.success));
        }
      } else {
        AppToast.error(context, _mapError(response?.message ?? ""));
        emit(state.copyWith(
          status: OtpStatus.failure,
          errorMessage: _mapError(response?.message ?? ""),
          digits: List.filled(state.otpLength, ''),
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: OtpStatus.failure,
        errorMessage: _mapError(e.toString().toLowerCase()),
        digits: List.filled(state.otpLength, ''),
      ));
    }
  }

  // ── Resend OTP ────────────────────────────────────────────────────────────
  Future<void> resend(String email, BuildContext context) async {
    if (!state.canResend) return;
    emit(state.copyWith(
      status: OtpStatus.resending,
      digits: List.filled(state.otpLength, ''),
      errorMessage: null,
    ));

    try {
      final deps = AppDependencies.of(context);
      String userEmail = deps.cache.getData(key: CacheKeys.userPhoneNumber);
      final response = await _authServices.resendSigningUpOtp(userEmail);
      if (response == "Verification code resent to your email") {
        AppToast.success(context, TranslationKey.successfullyResendOtp.tr());

        emit(state.copyWith(
          status: OtpStatus.resent,
          resendSeconds: 60,
          canResend: false,
        ));
        _startCountdown();
      }
    } catch (e) {
      String text = TranslationKey.errorResendOtp.tr();
      emit(state.copyWith(
          status: OtpStatus.failure,
          errorMessage: text
      ));
    }
  }

  // ── Countdown ────────────────────────────────────────────────────────────
  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.resendSeconds <= 1) {
        timer.cancel();
        emit(state.copyWith(resendSeconds: 0, canResend: true));
      } else {
        emit(state.copyWith(resendSeconds: state.resendSeconds - 1));
      }
    });
  }

  // ── Reset ─────────────────────────────────────────────────────────────────
  void reset() {
    _countdownTimer?.cancel();
    emit(OtpState(
      otpLength: state.otpLength,
      digits: List.filled(state.otpLength, ''),
    ));
    _startCountdown();
  }

  String _mapError(String e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('invalid') || msg.contains('incorrect') || msg.contains('wrong')) {
      return TranslationKey.wrongOtp;
    }
    if (msg.contains('expired')) {
      return TranslationKey.expiredOtp;
    }
    if (msg.contains('network') || msg.contains('socket')) {
      return TranslationKey.checkYourInternet.tr();
    }
    return TranslationKey.tryAgainLater.tr();
  }

  @override
  Future<void> close() {
    _countdownTimer?.cancel();
    return super.close();
  }
}