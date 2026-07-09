import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Shows daily quota counter + an inline finance-alert card when unpaid.
class DailyQuotaBanner extends StatelessWidget {
  final int todayCount;
  final int maxLimit;
  final bool isPaid;
  /// Called when user taps "مراجعة الحسابات" — open the dialog in PassesScreen.
  final VoidCallback? onFinanceTap;

  const DailyQuotaBanner({
    super.key,
    required this.todayCount,
    required this.maxLimit,
    required this.isPaid,
    this.onFinanceTap,
  });

  static const _blue = Color(0xFF008CFF);
  static const _dark = Color(0xFF003A70);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Finance alert widget (shown when NOT paid) ──────────────────
        if (!isPaid) _FinanceAlertCard(onTap: onFinanceTap),

        // ── Daily quota counter (always shown) ──────────────────────────
        _QuotaCounter(
          todayCount: todayCount,
          maxLimit: maxLimit,
          isPaid: isPaid,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Finance Alert Card  –  shown inline below the header when isPaid == false
// ─────────────────────────────────────────────────────────────────────────────
class _FinanceAlertCard extends StatefulWidget {
  final VoidCallback? onTap;
  const _FinanceAlertCard({this.onTap});

  @override
  State<_FinanceAlertCard> createState() => _FinanceAlertCardState();
}

class _FinanceAlertCardState extends State<_FinanceAlertCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          widget.onTap?.call();
        },
        child: Container(
          margin: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 6.h),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0050AA), Color(0xFF0088EE)],
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
            ),
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF008CFF).withOpacity(0.35),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              // Wallet icon bubble
              Container(
                width: 50.w,
                height: 50.w,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 26.sp,
                ),
              ),
              SizedBox(width: 14.w),

              // Text block
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'يرجى مراجعة الحسابات',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      'التجديد السنوي غير مسدّد — لا يمكن إضافة تصاريح حتى السداد',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12.sp,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10.w),

              // Arrow chip
              Container(
                padding:
                EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  'التفاصيل',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Daily Quota Counter Card
// ─────────────────────────────────────────────────────────────────────────────
class _QuotaCounter extends StatelessWidget {
  final int todayCount;
  final int maxLimit;
  final bool isPaid;

  const _QuotaCounter({
    required this.todayCount,
    required this.maxLimit,
    required this.isPaid,
  });

  static const _blue = Color(0xFF008CFF);
  static const _dark = Color(0xFF003A70);

  @override
  Widget build(BuildContext context) {
    final remaining = maxLimit - todayCount;
    final fraction = maxLimit > 0
        ? (todayCount / maxLimit).clamp(0.0, 1.0)
        : 0.0;
    final isFull = remaining <= 0;
    final activeColor = isFull ? const Color(0xFFD32F2F) : _blue;

    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isFull
              ? const Color(0xFFD32F2F).withOpacity(0.25)
              : const Color(0xFFB3D4FF),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Top row ──────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Big circular counter
              _CircleCounter(
                count: todayCount,
                max: maxLimit,
                isFull: isFull,
                isPaid: isPaid,
              ),
              SizedBox(width: 14.w),

              // Label + remaining text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'التصاريح اليومية',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        color: _dark,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      isFull
                          ? 'اكتملت التصاريح اليومية'
                          : !isPaid
                          ? 'مقفل — يرجى السداد أولاً'
                          : 'متبقي $remaining تصريح من أصل $maxLimit',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: isFull || !isPaid
                            ? const Color(0xFFD32F2F)
                            : const Color(0xFF4A6080),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Calendar icon button
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: activeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.calendar_today_rounded,
                  color: activeColor,
                  size: 18.sp,
                ),
              ),
            ],
          ),

          SizedBox(height: 14.h),

          // ── Progress bar ──────────────────────────────────────────────
          LayoutBuilder(builder: (ctx, constraints) {
            final barWidth = constraints.maxWidth;
            return Stack(
              children: [
                Container(
                  height: 7.h,
                  width: barWidth,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3EEFF),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOut,
                  height: 7.h,
                  width: barWidth * fraction,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isFull
                          ? [
                        const Color(0xFFD32F2F),
                        const Color(0xFFEF5350)
                      ]
                          : [
                        const Color(0xFF006FCC),
                        _blue,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Circular progress counter  (e.g. "0 / 6")
// ─────────────────────────────────────────────────────────────────────────────
class _CircleCounter extends StatelessWidget {
  final int count;
  final int max;
  final bool isFull;
  final bool isPaid;

  const _CircleCounter({
    required this.count,
    required this.max,
    required this.isFull,
    required this.isPaid,
  });

  static const _blue = Color(0xFF008CFF);

  @override
  Widget build(BuildContext context) {
    final activeColor = isFull || !isPaid
        ? const Color(0xFFD32F2F)
        : _blue;

    return Container(
      width: 58.w,
      height: 58.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: activeColor.withOpacity(0.08),
        border: Border.all(color: activeColor.withOpacity(0.3), width: 2),
      ),
      child: Center(
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: '$max',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                  color: activeColor,
                ),
              ),
              TextSpan(
                text: '\n/',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: activeColor.withOpacity(0.5),
                  height: 1.1,
                ),
              ),
              TextSpan(
                text: '$count',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: activeColor.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
