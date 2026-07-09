part of 'otp_cubit.dart';

enum OtpStatus { initial, loading, success, failure, resending, resent }

class OtpState extends Equatable {
  final OtpStatus status;
  final List<String> digits;       // 4 or 6 digits
  final int resendSeconds;         // countdown
  final bool canResend;
  final String? errorMessage;
  final int otpLength;

  const OtpState({
    this.status = OtpStatus.initial,
    this.digits = const ['', '', '', '', '', ''],
    this.resendSeconds = 60,
    this.canResend = false,
    this.errorMessage,
    this.otpLength = 6,
  });

  String get otpCode => digits.join();
  bool get isFilled => digits.every((d) => d.isNotEmpty);
  bool get isLoading => status == OtpStatus.loading;
  bool get isSuccess => status == OtpStatus.success;
  bool get isFailure => status == OtpStatus.failure;
  bool get isResending => status == OtpStatus.resending;

  OtpState copyWith({
    OtpStatus? status,
    List<String>? digits,
    int? resendSeconds,
    bool? canResend,
    String? errorMessage,
    int? otpLength,
  }) =>
      OtpState(
        status: status ?? this.status,
        digits: digits ?? this.digits,
        resendSeconds: resendSeconds ?? this.resendSeconds,
        canResend: canResend ?? this.canResend,
        errorMessage: errorMessage ?? this.errorMessage,
        otpLength: otpLength ?? this.otpLength,
      );

  @override
  List<Object?> get props => [
    status, digits, resendSeconds,
    canResend, errorMessage, otpLength,
  ];
}