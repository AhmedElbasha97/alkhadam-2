import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/colors/app_color.dart';
import '../theme/styles/app_styles.dart';
import '../theme/transelation/localization_key.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Toast Type
// ─────────────────────────────────────────────────────────────────────────────
enum ToastType { success, error, warning, info }

// ─────────────────────────────────────────────────────────────────────────────
// Toast Position
// ─────────────────────────────────────────────────────────────────────────────
enum ToastPosition { top, bottom }

// ─────────────────────────────────────────────────────────────────────────────
// Toast Config — style per type
// ─────────────────────────────────────────────────────────────────────────────
class _ToastConfig {
  final Color background;
  final Color iconBackground;
  final Color textColor;
  final Color borderColor;
  final IconData icon;
  final String defaultTitle;

  const _ToastConfig({
    required this.background,
    required this.iconBackground,
    required this.textColor,
    required this.borderColor,
    required this.icon,
    required this.defaultTitle,
  });
}

final Map<ToastType, _ToastConfig> _configs = {
  ToastType.success: _ToastConfig(
    background:AppColor.darkBlueColor,
    iconBackground: const Color(0xFF00C47A),
    textColor: Colors.white,
    borderColor: const Color(0xFF00C47A),
    icon: Icons.check_rounded,
    defaultTitle: TranslationKey.successTitle.tr(),
  ),
  ToastType.error: _ToastConfig(
    background:AppColor.darkBlueColor,
    iconBackground: AppColor.errorColor,
    textColor: AppColor.whiteTextColor,
    borderColor: AppColor.errorColor,
    icon: Icons.close_rounded,
    defaultTitle: TranslationKey.errorTitle.tr(),
  ),
  ToastType.warning:  _ToastConfig(
    background:AppColor.darkBlueColor,
    iconBackground: AppColor.lightPrimaryColor,
    textColor:  AppColor.whiteTextColor,
    borderColor:  AppColor.lightPrimaryColor,
    icon: Icons.warning_amber_rounded,
    defaultTitle: TranslationKey.warningTitle.tr(),
  ),
  ToastType.info:  _ToastConfig(
    background:AppColor.darkBlueColor,
    iconBackground: Color(0xFF3B82F6),
    textColor: Colors.white,
    borderColor: Color(0xFF3B82F6),
    icon: Icons.info_outline_rounded,
    defaultTitle: TranslationKey.infoTitle.tr(),
  ),
};

// ─────────────────────────────────────────────────────────────────────────────
// AppToast — static entry point
// ─────────────────────────────────────────────────────────────────────────────
class AppToast {
  AppToast._();

  static OverlayEntry? _current;
  static Timer? _timer;

  /// Show a toast. Call from anywhere with a BuildContext.
  static void show(
      BuildContext context, {
        required String message,
        String? title,
        ToastType type = ToastType.success,
        ToastPosition position = ToastPosition.top,
        Duration duration = const Duration(seconds: 3),
        OverlayState? fallbackOverlay, // 1. Added optional fallback parameter
      }) {
    _dismiss();

    final config = _configs[type]!;

    // 2. Look for overlay in context; if not found, use the fallback overlay state
    final overlay = Overlay.maybeOf(context) ?? fallbackOverlay;

    if (overlay == null) {
      debugPrint("AppToast Error: No Overlay found in the context tree or fallback.");
      return;
    }

    _current = OverlayEntry(
      builder: (_) => _ToastOverlay(
        message: message,
        title: title ?? config.defaultTitle,
        config: config,
        position: position,
        onDismiss: _dismiss,
      ),
    );

    overlay.insert(_current!);
    HapticFeedback.lightImpact();

    _timer = Timer(duration, _dismiss);
  }

  // ── Convenience shortcuts ─────────────────────────────────────────────────
  static void success(BuildContext context, String message, {String? title}) =>
      show(context, message: message, title: title, type: ToastType.success);

  static void error(BuildContext context, String message, {String? title, OverlayState? overlay}) =>
      show(context, message: message, title: title, type: ToastType.error, fallbackOverlay: overlay);

  static void warning(BuildContext context, String message, {String? title}) =>
      show(context, message: message, title: title, type: ToastType.warning);

  static void info(BuildContext context, String message, {String? title}) =>
      show(context, message: message, title: title, type: ToastType.info);

  static void _dismiss() {
    _timer?.cancel();
    _current?.remove();
    _current = null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Overlay wrapper — handles slide + fade animation
// ─────────────────────────────────────────────────────────────────────────────
class _ToastOverlay extends StatefulWidget {
  final String message;
  final String title;
  final _ToastConfig config;
  final ToastPosition position;
  final VoidCallback onDismiss;

  const _ToastOverlay({
    required this.message,
    required this.title,
    required this.config,
    required this.position,
    required this.onDismiss,
  });

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    final isTop = widget.position == ToastPosition.top;

    _slide = Tween<Offset>(
      begin: Offset(0, isTop ? -1 : 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));

    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scale = Tween<double>(begin: 0.88, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _animateDismiss() async {
    await _ctrl.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final isTop = widget.position == ToastPosition.top;
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Positioned(
      top: isTop ? topPad + 12.h : null,
      bottom: isTop ? null : bottomPad + 12.h,
      left: 16.w,
      right: 16.w,
      child: Material(
        color: Colors.transparent,
        child: SlideTransition(
          position: _slide,
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: GestureDetector(
                onTap: _animateDismiss,
                child: _ToastCard(
                  message: widget.message,
                  title: widget.title,
                  config: widget.config,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Toast Card — the visual
// ─────────────────────────────────────────────────────────────────────────────
class _ToastCard extends StatelessWidget {
  final String message;
  final String title;
  final _ToastConfig config;

  const _ToastCard({
    required this.message,
    required this.title,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: config.background,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: config.borderColor.withOpacity(0.45),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: config.borderColor.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _AnimatedIconBadge(
          icon: config.icon,
          background: config.iconBackground,
        ),
          const Spacer(),
         SizedBox(
            width: 220.w,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,

                  style: AppStyles.price(context).add(
                    color: config.textColor,
                    size: 14.sp,
                    weight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),

                  message.isNotEmpty?SizedBox(height: 3.h):SizedBox(),
                  message.isNotEmpty?Text(
                    message,
                    style: AppStyles.price(context).add(
                      color: config.textColor.withOpacity(0.7),
                      size: 12.sp,
                      height: 1.4,
                    ),
                  ):SizedBox(),

              ],
            ),
          ),
          SizedBox(width: 12.w),

          const Icon(Icons.close_rounded, color: AppColor.whiteTextColor, size: 16),

        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated icon badge with pulse ring
// ─────────────────────────────────────────────────────────────────────────────
class _AnimatedIconBadge extends StatefulWidget {
  final IconData icon;
  final Color background;

  const _AnimatedIconBadge({required this.icon, required this.background});

  @override
  State<_AnimatedIconBadge> createState() => _AnimatedIconBadgeState();
}

class _AnimatedIconBadgeState extends State<_AnimatedIconBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _ring;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: false);

    _ring = Tween<double>(begin: 0, end: 1.5).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44.w,
      height: 44.w,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulse ring
          AnimatedBuilder(
            animation: _ring,
            builder: (_, __) => Container(
              width: 44.w * (0.7 + _ring.value * 0.6),
              height: 44.w * (0.7 + _ring.value * 0.6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.background
                      .withOpacity((1.5 - _ring.value) * 0.5),
                  width: 1.5,
                ),
              ),
            ),
          ),
          // Icon circle
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: widget.background,
              shape: BoxShape.circle,
            ),
            child: Icon(widget.icon, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }
}