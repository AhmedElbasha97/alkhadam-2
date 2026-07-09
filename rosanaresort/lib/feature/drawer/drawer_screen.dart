// ============================================================
//  main_shell.dart  — the root scaffold that wraps:
//    • The passes/home screen (content area)
//    • A custom Rosana Drawer (left or right sliding)
//  ============================================================

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../config/routes/routes.dart';
import '../../../../core/cache/cache_consumer.dart';
import '../../../../core/dependencies/app_dependencies.dart';
import '../../../../core/theme/colors/app_color.dart';
import '../../../../core/theme/transelation/localization_key.dart';

class RosanaDrawer extends StatelessWidget {
  final VoidCallback onClose;
  const RosanaDrawer({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final cache = AppDependencies.of(context).cache;

    return Drawer(
      width: 300.w,
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────────────────
            _DrawerHeader(),
            const Divider(color: AppColor.dividerColor, height: 1),
            SizedBox(height: 8.h),

            // ── Nav items ──────────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                children: [
                  _DrawerItem(
                    icon: Icons.badge_outlined,
                    label: 'تصاريحي',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, Routes.passesScreen);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.add_circle_outline_rounded,
                    label: 'إضافة تصريح جديد',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, Routes.addPasses);
                    },
                    accent: true,
                  ),
                  _DrawerItem(
                    icon: Icons.person_outline_rounded,
                    label: 'الملف الشخصي',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, Routes.drawerProfilePage);
                    },
                  ),
                  SizedBox(height: 8.h),
                  const Divider(color: AppColor.dividerColor, height: 1),
                  SizedBox(height: 8.h),
                  _DrawerItem(
                    icon: Icons.privacy_tip_outlined,
                    label: 'سياسة الخصوصية',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, Routes.privacyPolicyPage);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.description_outlined,
                    label: 'الشروط والأحكام',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, Routes.termsPage);
                    },
                  ),
                ],
              ),
            ),

            // ── Footer version / branding ──────────────────────────────────
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  Icon(Icons.villa_rounded,
                      color: AppColor.lightPrimaryColor, size: 16.sp),
                  SizedBox(width: 6.w),
                  Text(
                    'منتجع روزانا',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColor.lightPrimaryColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Drawer header ─────────────────────────────────────────────────────────────

class _DrawerHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 20.h),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColor.primaryDeep, AppColor.lightPrimaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withOpacity(0.4), width: 1.5),
            ),
            child: Icon(Icons.villa_rounded,
                color: Colors.white, size: 28.sp),
          ),
          SizedBox(height: 12.h),
          Text(
            'منتجع روزانا',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'بوابة السكان',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.white.withOpacity(0.75),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Drawer item ──────────────────────────────────────────────────────────────

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool accent;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      leading: Container(
        width: 36.w,
        height: 36.w,
        decoration: BoxDecoration(
          color: accent
              ? AppColor.lightPrimaryColor.withOpacity(0.12)
              : AppColor.primaryLight,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(
          icon,
          size: 18.sp,
          color: accent
              ? AppColor.lightPrimaryColor
              : AppColor.primaryDeep,
        ),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: accent ? FontWeight.w700 : FontWeight.w500,
          color: accent
              ? AppColor.lightPrimaryColor
              : AppColor.lightSecondaryColor,
        ),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
    );
  }
}


