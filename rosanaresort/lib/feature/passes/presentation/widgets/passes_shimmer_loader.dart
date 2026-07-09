import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Animated shimmer skeleton that mirrors the PassCard + DailyQuotaBanner layout.
class PassesShimmerLoader extends StatefulWidget {
  final int cardCount;
  const PassesShimmerLoader({super.key, this.cardCount = 4});

  @override
  State<PassesShimmerLoader> createState() => _PassesShimmerLoaderState();
}

class _PassesShimmerLoaderState extends State<PassesShimmerLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat();
    _anim = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── Core shimmer box ──────────────────────────────────────────────────────
  Widget _box({
    required double width,
    required double height,
    double radius = 8,
  }) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: LinearGradient(
            begin: Alignment(_anim.value - 1, 0),
            end: Alignment(_anim.value + 1, 0),
            colors: const [
              Color(0xFFDCE8F5),
              Color(0xFFEEF4FC),
              Color(0xFFDCE8F5),
            ],
          ),
        ),
      ),
    );
  }

  Widget _line({double? width, double height = 14, double radius = 6}) {
    return LayoutBuilder(
      builder: (context, constraints) => _box(
        width: width ?? constraints.maxWidth,
        height: height,
        radius: radius,
      ),
    );
  }

  // ── Quota banner skeleton ─────────────────────────────────────────────────
  Widget _quotaBanner() {
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 4.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFB3D4FF)),
      ),
      child: Row(
        children: [
          _box(width: 44.w, height: 44.w, radius: 12),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _line(width: 120.w, height: 13),
                SizedBox(height: 8.h),
                _line(height: 8, radius: 4),
                SizedBox(height: 6.h),
                _line(width: 80.w, height: 10),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          _box(width: 48.w, height: 28.h, radius: 20),
        ],
      ),
    );
  }

  // ── Section header skeleton ───────────────────────────────────────────────
  Widget _sectionHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
      child: Row(
        children: [
          _box(width: 4.w, height: 18.h, radius: 2),
          SizedBox(width: 8.w),
          _line(width: 110.w, height: 13),
          const Spacer(),
          _box(width: 60.w, height: 24.h, radius: 20),
        ],
      ),
    );
  }

  // ── Single pass card skeleton ─────────────────────────────────────────────
  Widget _passCard() {
    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFFB3D4FF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(14.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar placeholder
            _box(width: 70.w, height: 70.w, radius: 16),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name row
                  Row(
                    children: [
                      Expanded(child: _line(height: 16)),
                      SizedBox(width: 8.w),
                      _box(width: 22.w, height: 22.w, radius: 11),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  // Caption
                  Row(
                    children: [
                      _box(width: 14.w, height: 14.w, radius: 7),
                      SizedBox(width: 5.w),
                      _line(width: 100.w, height: 11),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  // Dates
                  Row(
                    children: [
                      _box(width: 14.w, height: 14.w, radius: 7),
                      SizedBox(width: 5.w),
                      _line(width: 140.w, height: 11),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            // Status badge
            _box(width: 48.w, height: 24.h, radius: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        // Quota banner
        SliverToBoxAdapter(child: _quotaBanner()),

        // Section header
        SliverToBoxAdapter(child: _sectionHeader()),

        // Pass cards
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 100.h),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, __) => _passCard(),
              childCount: widget.cardCount,
            ),
          ),
        ),
      ],
    );
  }
}
