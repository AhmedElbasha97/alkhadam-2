import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rosanaresort/core/widgets/toast_widget.dart';
import '../../../../core/cache/cache_keys.dart';
import '../../../../core/dependencies/app_dependencies.dart';
import '../../../../core/theme/styles/app_styles.dart';
import '../../../drawer/drawer_screen.dart';
import '../cubit/passes_cubit.dart';
import '../cubit/passes_state.dart';
import '../widgets/pass_card.dart';
import '../widgets/finance_alert_banner.dart';
import '../widgets/daily_quota_banner.dart';
import '../widgets/passes_shimmer_loader.dart';
import '../widgets/passes_shimmer_loader.dart';

class PassesScreen extends StatefulWidget {
  final String unId;
  const PassesScreen({super.key, required this.unId});

  @override
  State<PassesScreen> createState() => _PassesScreenState();
}

class _PassesScreenState extends State<PassesScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fabAnim;
  late final Animation<double> _fabScale;

  static const _blue = Color(0xFF008CFF);
  static const _dark = Color(0xFF003A70);

  @override
  void initState() {
    super.initState();

    _fabAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fabScale = CurvedAnimation(parent: _fabAnim, curve: Curves.easeOutBack);


    final cubit = context.read<PassesCubit>();
    cubit.captureOpenLocation();
    cubit.loadPassesData(
    );
  }

  @override
  void dispose() {
    _fabAnim.dispose();
    super.dispose();
  }

  // ─── Dialog helpers (view-only, no business logic) ────────────────────────

  void _showFinanceDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24.r)),
          contentPadding: EdgeInsets.zero,
          content: Container(
            decoration:
            BoxDecoration(borderRadius: BorderRadius.circular(24.r)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCEEFF),
                    borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24.r)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 64.w,
                        height: 64.w,
                        decoration: BoxDecoration(
                          color:
                          const Color(0xFF008CFF).withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                            Icons.account_balance_wallet_rounded,
                            color: const Color(0xFF008CFF),
                            size: 32.sp),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'يرجى مراجعة الحسابات',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                          color: _dark,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    children: [
                      Text(
                        'لم يتم سداد التجديد السنوي بعد. يرجى التواصل مع إدارة المنتجع لتسوية حسابك وتفعيل إمكانية إضافة التصاريح.',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: const Color(0xFF4A6080),
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20.h),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(14.r)),
                            padding:
                            EdgeInsets.symmetric(vertical: 14.h),
                            elevation: 0,
                          ),
                          child: Text('حسناً، فهمت',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15.sp)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showQuotaDialog(int max) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24.r)),
          title: Row(
            children: [
              Icon(Icons.do_not_disturb_alt_rounded,
                  color: Colors.red.shade400, size: 24.sp),
              SizedBox(width: 8.w),
              Text('اكتمل الحد اليومي',
                  style: TextStyle(
                      fontSize: 17.sp, fontWeight: FontWeight.w800)),
            ],
          ),
          content: Text(
            'لقد أضفت الحد الأقصى من التصاريح لليوم ($max تصاريح). يمكنك الإضافة مجدداً غداً.',
            style: TextStyle(
                fontSize: 14.sp, color: const Color(0xFF4A6080)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('حسناً',
                  style: TextStyle(
                      color: _blue,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.sp)),
            )
          ],
        ),
      ),
    );
  }

  void _showVpnDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24)),
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
                  child: const Icon(Icons.gpp_bad_rounded,
                      color: Colors.redAccent, size: 42),
                ),
                const SizedBox(height: 20),
                Text(
                  'VPN محظور',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E3A8A),
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  'يُرجى إيقاف تشغيل الـ VPN قبل إضافة تصريح.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14.sp,
                      color: const Color(0xFF475569),
                      height: 1.6),
                ),
                SizedBox(height: 28.h),
                SizedBox(
                  width: double.infinity,
                  height: 52.h,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text('حسناً',
                        style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFakeLocationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24)),
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
                      size: 42),
                ),
                const SizedBox(height: 20),
                Text(
                  'موقع مزيف مكتشف',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E3A8A),
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  'تم اكتشاف موقع جغرافي مزيف. يُرجى تعطيل تطبيقات تغيير الموقع والمحاولة مجدداً.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14.sp,
                      color: const Color(0xFF475569),
                      height: 1.6),
                ),
                SizedBox(height: 28.h),
                SizedBox(
                  width: double.infinity,
                  height: 52.h,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      context.read<PassesCubit>().requestAddPass();
                    },
                    child: Text('إعادة المحاولة',
                        style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLocationRequiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24)),
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
                  child: const Icon(Icons.location_off_rounded,
                      color: Colors.amber, size: 42),
                ),
                const SizedBox(height: 20),
                Text(
                  'الموقع مطلوب',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E3A8A),
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  'يجب تفعيل خدمة الموقع للاستمرار في إضافة التصاريح.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14.sp,
                      color: const Color(0xFF475569),
                      height: 1.6),
                ),
                SizedBox(height: 28.h),
                SizedBox(
                  width: double.infinity,
                  height: 52.h,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      await Geolocator.openAppSettings();
                    },
                    child: Text('فتح الإعدادات',
                        style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          key: _scaffoldKey,
          drawer: RosanaDrawer(
            onClose: () => Navigator.pop(context),
          ),
          backgroundColor: const Color(0xFFF0F6FF),
          body: BlocConsumer<PassesCubit, PassesState>(
            listenWhen: (_, current) =>
            current is PassesLoaded ||
                current is PassesEmpty ||
                current is ShowVpnBlockedDialog ||
                current is ShowFakeLocationDialog ||
                current is ShowLocationRequiredDialog ||
                current is ShowFinanceBlockedDialog ||
                current is ShowQuotaExceededDialog ||
                current is OpenAddPassSheet ||
                current is StorePassSuccess ||
                current is StorePassError,
            listener: (context, state) {
              if (state is PassesLoaded || state is PassesEmpty) {
                _fabAnim.forward();
              } else if (state is ShowVpnBlockedDialog) {
                _showVpnDialog();
              } else if (state is ShowFakeLocationDialog) {
                _showFakeLocationDialog();
              } else if (state is ShowLocationRequiredDialog) {
                _showLocationRequiredDialog();
              } else if (state is ShowFinanceBlockedDialog) {
                _showFinanceDialog();
              } else if (state is ShowQuotaExceededDialog) {
                _showQuotaDialog(state.maxLimit);
              } else  if (state is StorePassSuccess) {
                AppToast.success(context, 'تمت إضافة التصريح بنجاح');
                final cubit = context.read<PassesCubit>();

                cubit.loadPassesData();
                AppToast.success(context, 'تمت إضافة التصريح بنجاح');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(children: [
                      const Icon(Icons.check_circle_rounded,
                          color: Colors.white, size: 20),
                      SizedBox(width: 10.w),
                      const Text('تمت إضافة التصريح بنجاح',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ]),
                    backgroundColor: const Color(0xFF00C47A),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r)),
                    margin: EdgeInsets.all(16.w),
                    duration: const Duration(seconds: 3),
                  ),
                );
              } else if (state is StorePassError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red.shade600,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r)),
                    margin: EdgeInsets.all(16.w),
                  ),
                );
              }
            },
            buildWhen: (_, current) =>
            current is PassesLoading ||
                current is PassesLoaded ||
                current is PassesEmpty ||
                current is PassesNullData ||
                current is PassesError ||
                current is PassesInitial,
            builder: (context, state) {
              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // ── Header (Hooked up to the drawer trigger callback) ──────
                  _RosanaHeader(
                    state: state,
                    onMenuTap: _openDrawer, // 🔥 Injected here
                    onAddTap: () =>
                        context.read<PassesCubit>().requestAddPass(),
                  ),

                  if (state is PassesLoading || state is PassesInitial)
                    const SliverFillRemaining(
                      child: PassesShimmerLoader(),
                    )
                  else if (state is PassesError)
                    SliverFillRemaining(
                      child: _ErrorView(
                        message: state.message,
                        onRetry: () =>
                            context.read<PassesCubit>().reloadPasses(),
                      ),
                    )
                  else if (state is PassesNullData)
                      SliverFillRemaining(
                        child: _NullDataView(
                          onRetry: () =>
                              context.read<PassesCubit>().reloadPasses(),
                        ),
                      )
                    else if (state is PassesEmpty) ...[
                        SliverToBoxAdapter(
                          child: DailyQuotaBanner(
                            todayCount: state.todayCount,
                            maxLimit: state.maxLimit,
                            isPaid: state.finance.isPaid,
                          ),
                        ),
                        SliverFillRemaining(
                          child: _EmptyView(
                            isPaid: state.finance.isPaid,
                            canAdd: state.canAddMore,
                            onAdd: () =>
                                context.read<PassesCubit>().requestAddPass(),
                          ),
                        ),
                      ]
                      else if (state is PassesLoaded) ...[
                          SliverToBoxAdapter(
                            child: DailyQuotaBanner(
                              todayCount: state.todayCount,
                              maxLimit: state.maxLimit,
                              isPaid: state.finance.isPaid,
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding:
                              EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 4.w,
                                    height: 18.h,
                                    decoration: BoxDecoration(
                                      color: _blue,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    'التصاريح المضافة',
                                    style: TextStyle(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w700,
                                      color: _dark,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 10.w, vertical: 4.h),
                                    decoration: BoxDecoration(
                                      color: _blue.withOpacity(0.12),
                                      borderRadius:
                                      BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${state.passes.length} تصريح',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w700,
                                        color: _blue,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                                16.w, 12.h, 16.w, 100.h),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                    (_, i) => PassCard(
                                  pass: state.passes[i],
                                  index: i,
                                ),
                                childCount: state.passes.length,
                              ),
                            ),
                          ),
                        ],
                ],
              );
            },
          ),

        ),
      ),
    );
  }
}

// ── Rosana branded header ─────────────────────────────────────────────────────
class _RosanaHeader extends StatelessWidget {
  final PassesState state;
  final VoidCallback? onAddTap;
  final VoidCallback? onMenuTap; // 🔥 Added parameter

  const _RosanaHeader({
    required this.state,
    this.onAddTap,
    this.onMenuTap, // 🔥 Formatted into constructor
  });

  static const _blue = Color(0xFF008CFF);
  static const _dark = Color(0xFF003A70);

  @override
  Widget build(BuildContext context) {
    final isLoaded = state is PassesLoaded;

    return SliverAppBar(
      pinned: true,
      expandedHeight: 180.h,
      backgroundColor: _dark,
      elevation: 0,
      automaticallyImplyLeading: false,
      // 🔥 Assigns the global drawer controller icon directly to the AppBar layout
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded, color: Colors.white),
        onPressed: onMenuTap,
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF003A70), Color(0xFF0070D6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -30,
                left: -20,
                child: Container(
                  width: 120.w,
                  height: 120.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: _blue.withOpacity(0.08), width: 28),
                  ),
                ),
              ),
              Positioned(
                bottom: -15,
                right: 60,
                child: Container(
                  width: 70.w,
                  height: 70.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: _blue.withOpacity(0.06), width: 18),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 40.h),
                      Row(
                        children: [
                          // Added padding adjustments to balance trailing content visually with leading icon
                          SizedBox(width: 32.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: _blue.withOpacity(0.15),
                              borderRadius:
                              BorderRadius.circular(8.r),
                              border: Border.all(
                                  color: _blue.withOpacity(0.3),
                                  width: 1),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.villa_rounded,
                                    color: _blue, size: 13.sp),
                                SizedBox(width: 5.w),
                                Text(
                                  'ROSANA RESORT',
                                  style: TextStyle(
                                    color: _blue,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),

                        ],
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'تصاريح الوحدة',
                        style: AppStyles.price(context).add(
                          color: Colors.white,
                          size: 26.sp,
                          weight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              color: Colors.white38, size: 13.sp),
                          SizedBox(width: 5.w),
                          Expanded(
                            child: Text(
                              isLoaded
                                  ? 'يمكنك إضافة وإصدار تصاريح دخول للزوار من هنا'
                                  : 'جارٍ تحميل البيانات...',
                              style: AppStyles.price(context).add(
                                color: Colors.white54,
                                size: 12.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      title: Row(
        children: [
          Icon(Icons.badge_outlined, color: _blue, size: 18.sp),
          SizedBox(width: 8.w),
          Text(
            'تصاريح الوحدة',
            style: AppStyles.price(context).add(
              color: Colors.white,
              size: 16.sp,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Null data view ────────────────────────────────────────────────────────────
class _NullDataView extends StatelessWidget {
  final VoidCallback onRetry;
  const _NullDataView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.inbox_rounded,
                  color: Colors.orange.shade300, size: 38.sp),
            ),
            SizedBox(height: 16.h),
            Text(
              'لا توجد بيانات',
              style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF003A70)),
            ),
            SizedBox(height: 8.h),
            Text(
              'لم يتم إرجاع أي بيانات من الخادم.',
              style: TextStyle(
                  fontSize: 13.sp, color: const Color(0xFF4A6080)),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF008CFF),
                side: const BorderSide(
                    color: Color(0xFF008CFF), width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r)),
                padding: EdgeInsets.symmetric(
                    horizontal: 24.w, vertical: 12.h),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty view ────────────────────────────────────────────────────────────────
class _EmptyView extends StatelessWidget {
  final bool isPaid;
  final bool canAdd;
  final VoidCallback onAdd;

  const _EmptyView(
      {required this.isPaid, required this.canAdd, required this.onAdd});

  static const _blue = Color(0xFF008CFF);
  static const _dark = Color(0xFF003A70);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100.w,
              height: 100.w,
              decoration: const BoxDecoration(
                color: Color(0xFFE3EEFF),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.badge_outlined,
                  size: 48.sp, color: const Color(0xFF4A6080)),
            ),
            SizedBox(height: 20.h),
            Text(
              'لا توجد تصاريح حالية للوحدة',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: _dark,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              isPaid
                  ? 'اضغط على زر "إضافة تصريح" لإصدار تصريح دخول جديد للزوار'
                  : 'يرجى مراجعة الحسابات وسداد التجديد السنوي لتفعيل إضافة التصاريح',
              style: TextStyle(
                  fontSize: 14.sp,
                  color: const Color(0xFF4A6080),
                  height: 1.6),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 28.h),
            if (canAdd)
              GestureDetector(
                onTap: onAdd,
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 28.w, vertical: 14.h),
                  decoration: BoxDecoration(
                    color: _blue,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: _blue.withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded,
                          color: Colors.white, size: 20.sp),
                      SizedBox(width: 8.w),
                      Text(
                        'إضافة تصريح',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.cloud_off_rounded,
                  color: Colors.red.shade300, size: 38.sp),
            ),
            SizedBox(height: 16.h),
            Text(
              'تعذّر تحميل البيانات',
              style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF003A70)),
            ),
            SizedBox(height: 8.h),
            Text(
              message,
              style: TextStyle(
                  fontSize: 13.sp, color: const Color(0xFF4A6080)),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF008CFF),
                side: const BorderSide(
                    color: Color(0xFF008CFF), width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r)),
                padding: EdgeInsets.symmetric(
                    horizontal: 24.w, vertical: 12.h),
              ),
            ),
          ],
        ),
      ),
    );
  }
}