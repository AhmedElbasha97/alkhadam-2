import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/colors/app_color.dart';
import '../../../../core/theme/images/app_images.dart';
import '../../../../core/theme/styles/app_styles.dart';
import '../../../../core/theme/transelation/localization_cubit.dart';
import '../../../../core/theme/transelation/localization_key.dart';
import '../cubit/otp_cubit.dart';
import '../widget/otp_row_widget.dart';

// ── Arguments ─────────────────────────────────────────────────────────────
class OtpPageArgs {
  final String email;
  final String maskedEmail;
  final int otpLength;
  final bool isComingFromSigningUp;

  const OtpPageArgs({
    required this.email,
    required this.maskedEmail,
    this.otpLength = 6,
    required this.isComingFromSigningUp,
  });
}

// ── Main Page ─────────────────────────────────────────────────────────────
class OtpPage extends StatefulWidget {
  final OtpPageArgs args;

  const OtpPage({super.key, required this.args});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> with TickerProviderStateMixin {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  // Animation Controllers
  late final AnimationController _successCtrl;
  late final Animation<double> _successScale;
  late final Animation<double> _successFade;
  late final AnimationController _checkCtrl;
  late final Animation<double> _checkDraw;

  @override
  void initState() {
    super.initState();
    final len = widget.args.otpLength;
    _controllers = List.generate(len, (_) => TextEditingController());
    _focusNodes = List.generate(len, (_) => FocusNode());

    // Auto-focus first box
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });

    _successCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _successScale = Tween<double>(begin: 0.4, end: 1).animate(
      CurvedAnimation(parent: _successCtrl, curve: Curves.easeOutBack),
    );
    _successFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _successCtrl, curve: Curves.easeOut),
    );

    _checkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _checkDraw = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _checkCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    _successCtrl.dispose();
    _checkCtrl.dispose();
    super.dispose();
  }

  void _onDigitChanged(int index) {
    context.read<OtpCubit>().updateDigit(index, _controllers[index].text);
  }

  void _onCompleted(BuildContext context) {
    FocusScope.of(context).unfocus();

      context.read<OtpCubit>().verifyForForgetPass(widget.args.email, context);

  }


  Future<void> _openWhatsApp() async {
    final bool isArabic = context.read<LocalizationCubit>().isArabic();

    // Configured bot number
    const String phoneNumber = "+201288966659";

    // Bot Trigger Command
    final String message = isArabic
        ? "طلب رمز التحقق OTP"
        : "Request OTP Code";

    final Uri whatsappUri = Uri.parse("https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}");

    try {
      await launchUrl(
        whatsappUri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint("WhatsApp error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isArabic = context.read<LocalizationCubit>().isArabic();

    return BlocListener<OtpCubit, OtpState>(
      listener: (context, state) {
        if (state.isSuccess) {
        }
        if (state.isFailure || state.status == OtpStatus.resent) {
          // Clear boxes on failure
          for (int i = 0; i < _controllers.length; i++) {
            _controllers[i].clear();
          }
          if (state.isFailure) {
            _focusNodes[0].requestFocus();
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leadingWidth: 120.w,
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,

          actions: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                 Icons.arrow_forward_ios_rounded,
                color: AppColor.lightSecondaryColor,
                size: 22.sp,
              ),
            ),
            SizedBox(width: 8.w),
          ],
        ),
        body: Stack(
          children: [
            _buildBody(isArabic),

          ],
        ),
      ),
    );
  }

  Widget _buildBody(bool isArabic) {
    return BlocBuilder<OtpCubit, OtpState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              SizedBox(height: 32.h),

              // ── Shield Icon ──────────────────────────────────────────
              _ShieldIcon(isError: state.isFailure),
              SizedBox(height: 24.h),

              // ── Title ────────────────────────────────────────────────
              Text(
                TranslationKey.otpTitle.tr(),
                style: AppStyles.price(context).add(
                  color: AppColor.lightSecondaryColor,
                  size: 26.sp,
                  weight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 12.h),

              // ── Subtitle ─────────────────────────────────────────────
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: AppStyles.body(context).add(
                    size: 14.sp,
                    color: AppColor.lightGreyColor,
                    height: 1.6,
                  ),
                  children: [
                    TextSpan(text: "${TranslationKey.otpText.tr()} "),
                    TextSpan(
                      text: widget.args.maskedEmail,
                      style: AppStyles.body(context).add(
                        color: AppColor.lightSecondaryColor,
                        weight: FontWeight.w700,
                        size: 15.sp,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40.h),

              // ── OTP Boxes Row Entry Component ───────────────────────
              OtpInputRow(
                length: state.otpLength,
                isError: state.isFailure,
                digits: state.digits,
                controllers: _controllers,
                focusNodes: _focusNodes,
                onDigitChanged: _onDigitChanged,
                onCompleted: () => _onCompleted(context),
              ),
              SizedBox(height: 48.h),

              // ── Verify Main Action Button ────────────────────────────
              _VerifyButton(
                isFilled: state.isFilled,
                isLoading: state.isLoading,
                onTap: () => _onCompleted(context),
              ),

              SizedBox(height: 32.h),

              // ── Visual Divider ─────────────────────────────────────────
              Row(
                children: [
                  Expanded(child: Divider(color: AppColor.lightGreyColor.withOpacity(0.3), thickness: 1)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    child: Text(
                      isArabic ? "لم تستلم الرمز؟" : "Didn't receive the code?",
                      style: TextStyle(
                        color: AppColor.lightGreyColor,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: AppColor.lightGreyColor.withOpacity(0.3), thickness: 1)),
                ],
              ),

              SizedBox(height: 20.h),

              // ── WhatsApp Bot Trigger Card ─────────────────────────────
              _WhatsAppTriggerCard(
                onPressed: _openWhatsApp,
                isArabic: isArabic,
              ),
              SizedBox(height: 40.h),
            ],
          ),
        );
      },
    );
  }
}

// ── Components & Animations ───────────────────────────────────────────────

class _WhatsAppTriggerCard extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isArabic;

  const _WhatsAppTriggerCard({required this.onPressed, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: const Color(0xFF25D366).withOpacity(0.08),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFF25D366).withOpacity(0.2), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat, color: Color(0xFF1DA851), size: 26),
            SizedBox(width: 12.w),
            Text(
              isArabic ? "استلام الرمز عبر واتساب" : "Receive code via WhatsApp",
              style: TextStyle(
                color: const Color(0xFF1DA851),
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShieldIcon extends StatefulWidget {
  final bool isError;
  const _ShieldIcon({required this.isError});

  @override
  State<_ShieldIcon> createState() => _ShieldIconState();
}

class _ShieldIconState extends State<_ShieldIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _float;
  late final Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _float, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _floatAnim,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _floatAnim.value),
        child: child,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 90.w,
        height: 90.w,
        decoration: BoxDecoration(
          color: widget.isError
              ? AppColor.errorColor.withOpacity(0.08)
              : AppColor.lightPrimaryColor.withOpacity(0.08),
          shape: BoxShape.circle,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 68.w,
              height: 68.w,
              decoration: BoxDecoration(
                color: widget.isError
                    ? AppColor.errorColor.withOpacity(0.15)
                    : AppColor.lightPrimaryColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
            ),
            Icon(
              widget.isError ? Icons.shield_outlined : Icons.shield_rounded,
              size: 38.w,
              color: widget.isError ? AppColor.errorColor : AppColor.lightPrimaryColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _VerifyButton extends StatelessWidget {
  final bool isFilled;
  final bool isLoading;
  final VoidCallback onTap;

  const _VerifyButton({
    required this.isFilled,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isFilled && !isLoading ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        width: double.infinity,
        height: 54.h,
        decoration: BoxDecoration(
          color: isFilled ? AppColor.lightPrimaryColor : AppColor.lightGreyColor.withAlpha(80),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: isFilled
              ? [
            BoxShadow(
              color: AppColor.lightPrimaryColor.withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ]
              : [],
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColor.whiteTextColor,
            ),
          )
              : Text(
            TranslationKey.otpButtonTitle.tr(),
            style: TextStyle(
              color: isFilled ? AppColor.whiteTextColor : AppColor.lightGreyColor,
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _SuccessOverlay extends StatelessWidget {
  final Animation<double> fadeAnim;
  final Animation<double> scaleAnim;
  final Animation<double> checkAnim;

  const _SuccessOverlay({
    required this.fadeAnim,
    required this.scaleAnim,
    required this.checkAnim,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnim,
      child: Container(
        color: Colors.white.withOpacity(0.96),
        child: Center(
          child: ScaleTransition(
            scale: scaleAnim,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 100.w,
                  height: 100.w,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 100.w,
                        height: 100.w,
                        decoration: BoxDecoration(
                          color: AppColor.successColor.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 76.w,
                        height: 76.w,
                        decoration: const BoxDecoration(
                          color: AppColor.successColor,
                          shape: BoxShape.circle,
                        ),
                        child: AnimatedBuilder(
                          animation: checkAnim,
                          builder: (_, __) => CustomPaint(
                            painter: _CheckPainter(progress: checkAnim.value),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),
                Text(
                  TranslationKey.otpVerificationSuccessTitle.tr(),
                  style: AppStyles.price(context).add(
                    color: AppColor.lightSecondaryColor,
                    size: 22.sp,
                    weight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  TranslationKey.otpVerificationSuccessText.tr(),
                  style: AppStyles.body(context).add(
                    color: AppColor.lightGreyColor,
                    size: 14.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  final double progress;

  const _CheckPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    final cy = size.height / 2;

    final p1 = Offset(cx - 15, cy);
    final p2 = Offset(cx - 3, cy + 12);
    final p3 = Offset(cx + 15, cy - 12);

    final seg1Length = (p2 - p1).distance;
    final seg2Length = (p3 - p2).distance;
    final total = seg1Length + seg2Length;
    final drawn = progress * total;

    final path = Path();
    if (drawn <= seg1Length) {
      final t = drawn / seg1Length;
      path.moveTo(p1.dx, p1.dy);
      path.lineTo(p1.dx + (p2.dx - p1.dx) * t, p1.dy + (p2.dy - p1.dy) * t);
    } else {
      path.moveTo(p1.dx, p1.dy);
      path.lineTo(p2.dx, p2.dy);
      final t = (drawn - seg1Length) / seg2Length;
      path.lineTo(p2.dx + (p3.dx - p2.dx) * t, p2.dy + (p3.dy - p2.dy) * t);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.progress != progress;
}