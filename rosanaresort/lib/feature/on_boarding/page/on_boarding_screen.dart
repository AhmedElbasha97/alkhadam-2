import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rosanaresort/core/theme/images/app_images.dart';

import '../../../config/routes/routes.dart';
import '../../../core/cache/cache_keys.dart';
import '../../../core/dependencies/app_dependencies.dart';
import '../../../core/theme/styles/app_styles.dart';
import '../cubit/on_boarding_cubit.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();

  late final AnimationController _entryCtrl;
  late final Animation<double> _entryFade;
  late final Animation<Offset> _entrySlide;

  // Track per-page text animations
  late final AnimationController _textCtrl;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;

  final List<_OnboardingItem> items = [
    _OnboardingItem(
      title: 'مرحباً بك في روزانا',
      desc:
      'استمتع بتجربة إقامة فاخرة وخدمات متكاملة مخصصة لراحتك داخل المنتجع.',
      icon: AppImages.onboarding1,
      accent: const Color(0xFF0E8982),
    ),
    _OnboardingItem(
      title: 'تصاريح دخول سريعة',
      desc:
      'أصدر تصاريح الزوار والمرافقين بكل سهولة وأمان دون تضييع للوقت عند البوابات.',
      icon: AppImages.onboarding2,
      accent: const Color(0xFFCF9F1A),
    ),
    _OnboardingItem(
      title: 'إقامة آمنة وموثوقة',
      desc:
      'نظام حماية متطور يعتمد على التحقق الجغرافي لضمان سلامتك وسلامة عائلتك.',
      icon: AppImages.onboarding3,
      accent: const Color(0xFF1E3A8A),
    ),
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _entryFade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entrySlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));

    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();

    _textFade = CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut);
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _entryCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  void _onPageChanged(BuildContext context, int index) {
    context.read<OnboardingCubit>().onPageChanged(index);
    _textCtrl.forward(from: 0);
    HapticFeedback.selectionClick();
  }

  void _navigateToLogin(BuildContext context) {
    final deps = AppDependencies.of(context);
    deps.cache.saveData(key: CacheKeys.onboardingDone, value: true);
    Navigator.of(context).pushNamed(Routes.signInPage);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return BlocProvider(
      create: (_) => OnboardingCubit(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: BlocBuilder<OnboardingCubit, int>(
          builder: (context, currentIndex) {
            final item = items[currentIndex];
            final isLast = currentIndex == items.length - 1;

            return Stack(
              children: [
                // ── Full-bleed hero image (top 55%) ───────────────────────
                FadeTransition(
                  opacity: _entryFade,
                  child: SizedBox(
                    height: size.height*0.95,
                    width: double.infinity,
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (i) => _onPageChanged(context, i),
                      itemCount: items.length,
                      itemBuilder: (_, i) => _HeroImage(image: items[i].icon),
                    ),
                  ),
                ),

                // ── Bottom gradient fade over image ───────────────────────
                Positioned(
                  top: size.height * 0.44,
                  left: 0,
                  right: 0,
                  height: size.height * 0.22,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.white],
                      ),
                    ),
                  ),
                ),

                // ── Content panel ─────────────────────────────────────────
                Positioned(
                  top: size.height * 0.64,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(28, 10, 28, 0),
                    child: SlideTransition(
                      position: _entrySlide,
                      child: FadeTransition(
                        opacity: _entryFade,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Accent tag ────────────────────────────────
                            SlideTransition(
                              position: _textSlide,
                              child: FadeTransition(
                                opacity: _textFade,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: item.accent.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${currentIndex + 1} / ${items.length}',
                                    style: TextStyle(
                                      color: item.accent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // ── Title ─────────────────────────────────────
                            SlideTransition(
                              position: _textSlide,
                              child: FadeTransition(
                                opacity: _textFade,
                                child: Text(
                                  item.title,
                                  style: AppStyles.price(context).add(
                                    size: 26,
                                    weight: FontWeight.w800,
                                    color: const Color(0xFF0D1B2A),
                                    height: 1.25,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // ── Description ───────────────────────────────
                            SlideTransition(
                              position: _textSlide,
                              child: FadeTransition(
                                opacity: _textFade,
                                child: Text(
                                  item.desc,
                                  style: AppStyles.price(context).add(
                                    size: 15,
                                    color: const Color(0xFF64748B),
                                    height: 1.65,
                                  ),
                                ),
                              ),
                            ),

                            const Spacer(),

                            // ── Controls row ──────────────────────────────
                            Row(
                              children: [
                                // Dot indicators
                                Row(
                                  children: List.generate(
                                    items.length,
                                        (i) => _Dot(
                                      isActive: i == currentIndex,
                                      color: item.accent,
                                    ),
                                  ),
                                ),
                                const Spacer(),

                                // Skip / Next CTA
                                if (!isLast)
                                  TextButton(
                                    onPressed: () =>
                                        _navigateToLogin(context),
                                    child: Text(
                                      'تخطي',
                                      style: AppStyles.price(context).add(
                                        color: const Color(0xFF94A3B8),
                                        size: 15,
                                        weight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 8),

                                // Next / Start button
                                _NextButton(
                                  isLast: isLast,
                                  accent: item.accent,
                                  onTap: () {
                                    if (isLast) {
                                      _navigateToLogin(context);
                                    } else {
                                      _pageController.nextPage(
                                        duration:
                                        const Duration(milliseconds: 450),
                                        curve: Curves.easeInOutCubic,
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 36),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Safe area skip button top ─────────────────────────────
                if (currentIndex < items.length - 1)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16, top: 8),
                          child: TextButton(
                            onPressed: () => _navigateToLogin(context),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.black26,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 6),
                            ),
                            child: const Text(
                              'تخطي',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Hero image with parallax cover ───────────────────────────────────────────
class _HeroImage extends StatelessWidget {
  final String image;
  const _HeroImage({required this.image});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(image, fit: BoxFit.cover),
        // Subtle vignette
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.05),
                Colors.black.withOpacity(0.25),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Animated dot ──────────────────────────────────────────────────────────────
class _Dot extends StatelessWidget {
  final bool isActive;
  final Color color;
  const _Dot({required this.isActive, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(right: 6),
      height: 8,
      width: isActive ? 28 : 8,
      decoration: BoxDecoration(
        color: isActive ? color : const Color(0xFFCBD5E1),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

// ── Next / Start button ───────────────────────────────────────────────────────
class _NextButton extends StatelessWidget {
  final bool isLast;
  final Color accent;
  final VoidCallback onTap;
  const _NextButton(
      {required this.isLast, required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 52,
        width: isLast ? 160 : 52,
        decoration: BoxDecoration(
          color: accent,
          borderRadius: BorderRadius.circular(isLast ? 16 : 26),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: isLast
              ? const Text(
            'ابدأ الآن',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          )
              : const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────────
class _OnboardingItem {
  final String title;
  final String desc;
  final String icon;
  final Color accent;
  const _OnboardingItem(
      {required this.title,
        required this.desc,
        required this.icon,
        required this.accent});
}