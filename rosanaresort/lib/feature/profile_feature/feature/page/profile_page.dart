// ============================================================
//  profile_screen.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../config/routes/routes.dart';
import '../../../../core/theme/colors/app_color.dart';
import '../../../drawer/drawer_screen.dart';
import '../cubit/profile_cubit.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ProfileCubit>().loadProfile();
  }

  // ── Logout alert ───────────────────────────────────────────────────────────
  Future<void> _showLogoutDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black45,
      builder: (ctx) => const _RosanaDialog(
        icon: Icons.logout_rounded,
        iconColor: AppColor.lightPrimaryColor,
        title: "تسجيل الخروج",
        message: "هل أنت متأكد من رغبتك في تسجيل الخروج من الحساب؟",
        confirmLabel: "تسجيل الخروج",
        confirmColor: AppColor.lightPrimaryColor,
        cancelLabel: "إلغاء",
      ),
    );
    if (confirmed == true && mounted) {
      context.read<ProfileCubit>().logout();
    }
  }

  // ── Delete account alert ────────────────────────────────────────────────────
  Future<void> _showDeleteAccountDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black45,
      builder: (ctx) => const _RosanaDialog(
        icon: Icons.delete_forever_rounded,
        iconColor: AppColor.errorColor,
        title: "حذف الحساب",
        message: "هل أنت متأكد من رغبتك في حذف حسابك نهائياً؟ هذا الإجراء لا يمكن التراجع عنه.",
        confirmLabel: "حذف الحساب",
        confirmColor: AppColor.errorColor,
        cancelLabel: "إلغاء",
        isDangerous: true,
      ),
    );
    if (confirmed == true && mounted) {
      context.read<ProfileCubit>().deleteAccount();
    }
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCubit, ProfileState>(
      listenWhen: (prev, curr) =>
      curr.logoutSuccess != prev.logoutSuccess ||
          curr.deleteAccountSuccess != prev.deleteAccountSuccess ||
          (curr.errorMessage != null && curr.errorMessage != prev.errorMessage),
      listener: (context, state) {
        if (state.logoutSuccess || state.deleteAccountSuccess) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            Routes.signInPage,
                (route) => false,
          );
        } else if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColor.errorColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r)),
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColor.lightBackGroundColor,
          appBar: _buildAppBar(context),
          key: _scaffoldKey,
          drawer: RosanaDrawer(
            onClose: () => Navigator.pop(context),
          ),
          body: state.isLoading
              ? _ProfileShimmer()
              : _ProfileBody(
            state: state,
            onLogout: _showLogoutDialog,
            onDeleteAccount: _showDeleteAccountDialog,
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColor.primaryDeep,
      elevation: 0,
      automaticallyImplyLeading: false,
      leadingWidth: 56.w,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 20.sp),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: const Text(
        "الملف الشخصي",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
     actions:[ IconButton(
        icon: const Icon(Icons.menu_rounded, color: Colors.white),
        onPressed: _openDrawer,
      ),],
      centerTitle: true,
    );
  }
}

// ── Profile body ──────────────────────────────────────────────────────────────

class _ProfileBody extends StatelessWidget {
  final ProfileState state;
  final VoidCallback onLogout;
  final VoidCallback onDeleteAccount;

  const _ProfileBody({
    required this.state,
    required this.onLogout,
    required this.onDeleteAccount,
  });

  @override
  Widget build(BuildContext context) {
    final user = state.user;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: _ProfileHero(user: user),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 16.h)),
        if (state.unitDetails != null)
          SliverToBoxAdapter(
            child: _UnitDetailsCard(unit: state.unitDetails!),
          ),
        SliverToBoxAdapter(
          child: _InfoSection(
            title: "المعلومات الشخصية",
            tiles: [
              _InfoTile(
                icon: Icons.person_outline_rounded,
                label: "الاسم الكامل",
                value: user?.fullName ?? '—',
              ),
              _InfoTile(
                icon: Icons.card_membership,
                label: "الرقم القومي",
                value: user?.email ?? '—',
              ),
              _InfoTile(
                icon: Icons.phone_outlined,
                label: "رقم الهاتف",
                value: user?.phone ?? '—',
              ),
            ],
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 12.h)),
        SliverToBoxAdapter(
          child: _DangerSection(
            onLogout: onLogout,
            onDeleteAccount: onDeleteAccount,
            isLoggingOut: state.isLoggingOut,
            isDeleting: state.isDeleting,
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 32.h)),
      ],
    );
  }
}

// ── Profile hero card ──────────────────────────────────────────────────────────

class _ProfileHero extends StatelessWidget {
  final dynamic user;
  const _ProfileHero({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColor.primaryDeep, AppColor.lightPrimaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: AppColor.lightPrimaryColor.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                user?.fullName ?? '—',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                user?.title ?? '',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.white.withOpacity(0.75),
                ),
              ),
              SizedBox(height: 4.h),
              Container(
                padding:
                EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: const Text(
                  'منتجع روزانا',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ), SizedBox(width: 16.w),
          Container(
            width: 72.w,
            height: 72.w,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
            ),
            child: Icon(Icons.person_rounded,
                size: 36.sp, color: Colors.white.withOpacity(0.9)),
          ),


        ],
      ),
    );
  }
}

// ── Unit details card ─────────────────────────────────────────────────────────

class _UnitDetailsCard extends StatelessWidget {
  final dynamic unit;
  const _UnitDetailsCard({required this.unit});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 0),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColor.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.villa_rounded,
                  color: AppColor.lightPrimaryColor, size: 18.sp),
              SizedBox(width: 8.w),
              const Text(
                'معلومات الوحدة',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColor.primaryDeep,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: unit.financeStatus
                      ? AppColor.successColor.withOpacity(0.1)
                      : AppColor.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  unit.financeStatus ? 'نشط' : 'موقوف',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: unit.financeStatus
                        ? AppColor.successColor
                        : AppColor.errorColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 16.w,
            runSpacing: 8.h,
            children: [
              _UnitChip(
                  icon: Icons.business_rounded,
                  label: unit.buildingNumber,
                  prefix: 'مبنى'),
              _UnitChip(
                  icon: Icons.layers_rounded,
                  label: unit.floorNumber,
                  prefix: 'طابق'),
              _UnitChip(
                  icon: Icons.door_back_door_rounded,
                  label: unit.apartmentNumber,
                  prefix: 'وحدة'),
            ],
          ),
        ],
      ),
    );
  }
}

class _UnitChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String prefix;
  const _UnitChip(
      {required this.icon, required this.label, required this.prefix});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColor.primaryLight,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Text(
          '$prefix: $label',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColor.primaryDeep,
          ),
        ),SizedBox(width: 5.w),
          Icon(icon, size: 14.sp, color: AppColor.lightPrimaryColor),


        ],
      ),
    );
  }
}

// ── Info section ──────────────────────────────────────────────────────────────

class _InfoSection extends StatelessWidget {
  final String title;
  final List<Widget> tiles;

  const _InfoSection({required this.title, required this.tiles});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColor.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColor.lightGreyColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(height: 8.h),
          ...tiles,
          SizedBox(height: 4.h),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Row(
        children: [ Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColor.lightGreyColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColor.lightSecondaryColor,
                ),
              ),
            ],
          ),
        ), SizedBox(width: 12.w),
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: AppColor.primaryLight,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, size: 18.sp, color: AppColor.lightPrimaryColor),
          ),


        ],
      ),
    );
  }
}

// ── Danger zone ───────────────────────────────────────────────────────────────

class _DangerSection extends StatelessWidget {
  final VoidCallback onLogout;
  final VoidCallback onDeleteAccount;
  final bool isLoggingOut;
  final bool isDeleting;

  const _DangerSection({
    required this.onLogout,
    required this.onDeleteAccount,
    required this.isLoggingOut,
    required this.isDeleting,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          _ActionButton(
            icon: Icons.logout_rounded,
            label: "تسجيل الخروج",
            color: AppColor.lightPrimaryColor,
            isLoading: isLoggingOut,
            onTap: onLogout,
          ),
          SizedBox(height: 10.h),
          _ActionButton(
            icon: Icons.delete_forever_rounded,
            label: "حذف الحساب",
            color: AppColor.errorColor,
            isLoading: isDeleting,
            onTap: onDeleteAccount,
            outlined: true,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isLoading;
  final VoidCallback onTap;
  final bool outlined;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isLoading,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: isLoading ? null : onTap,
          icon: isLoading
              ? SizedBox(
            width: 18.w,
            height: 18.w,
            child: CircularProgressIndicator(strokeWidth: 2, color: color),
          )
              : Icon(icon, size: 18.sp),
          label: Text(label,
              style:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color, width: 1.5),
            padding: EdgeInsets.symmetric(vertical: 14.h),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r)),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onTap,
        icon: isLoading
            ? SizedBox(
          width: 18.w,
          height: 18.w,
          child: const CircularProgressIndicator(
              strokeWidth: 2, color: Colors.white),
        )
            : Icon(icon, size: 18.sp),
        label: Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(vertical: 14.h),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.r)),
        ),
      ),
    );
  }
}

// ── Shimmer loader ────────────────────────────────────────────────────────────

class _ProfileShimmer extends StatefulWidget {
  @override
  State<_ProfileShimmer> createState() => _ProfileShimmerState();
}

class _ProfileShimmerState extends State<_ProfileShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        duration: const Duration(milliseconds: 1300), vsync: this)
      ..repeat();
    _anim = Tween<double>(begin: -2, end: 2).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _box({required double w, required double h, double r = 10}) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(r),
          gradient: LinearGradient(
            begin: Alignment(_anim.value - 1, 0),
            end: Alignment(_anim.value + 1, 0),
            colors: const [
              Color(0xFFDCEEFF),
              Color(0xFFEEF6FF),
              Color(0xFFDCEEFF)
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          _box(w: double.infinity, h: 120.h, r: 24),
          SizedBox(height: 16.h),
          _box(w: double.infinity, h: 180.h, r: 20),
        ],
      ),
    );
  }
}

// ── Reusable Rosana dialog ─────────────────────────────────────────────────────

class _RosanaDialog extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String confirmLabel;
  final Color confirmColor;
  final String cancelLabel;
  final bool isDangerous;

  const _RosanaDialog({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.confirmColor,
    required this.cancelLabel,
    this.isDangerous = false,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64.w,
              height: 64.w,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 32.sp),
            ),
            SizedBox(height: 16.h),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColor.primaryDeep,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10.h),
            Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: AppColor.lightGreyColor,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColor.lightGreyColor,
                      side: BorderSide(color: AppColor.borderColor),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r)),
                      padding: EdgeInsets.symmetric(vertical: 13.h),
                    ),
                    child: Text(cancelLabel,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: confirmColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r)),
                      padding: EdgeInsets.symmetric(vertical: 13.h),
                    ),
                    child: Text(confirmLabel,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}