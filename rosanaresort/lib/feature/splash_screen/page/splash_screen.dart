import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rosanaresort/core/theme/images/app_images.dart';

import '../../../config/routes/routes.dart';
import '../../../core/cache/cache_keys.dart';
import '../../../core/dependencies/app_dependencies.dart';
import '../../auth/otp/presentation/Otp_screen.dart';
import '../cubit/aplsh_cubit.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );

    context.read<SplashCubit>().initializeApp(context);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String maskPhoneNumber(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-()]+'), '');
    if (cleaned.length < 8) return phone;
    final int prefixLen = cleaned.startsWith('+') ? 4 : 3;
    final String prefix = cleaned.substring(0, prefixLen);
    final String suffix = cleaned.substring(cleaned.length - 2);
    final String mask = '*' * (cleaned.length - prefixLen - 2);
    return '$prefix$mask$suffix';
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SplashCubit, SplashState>(
      listener: (context, state) {
        if (state is NavigateToOnboarding) {
          Navigator.of(context).pushReplacementNamed(Routes.onboardingScreen);
        } else if (state is NavigateToLogin) {
          Navigator.of(context).pushReplacementNamed(Routes.signInPage);
        } else if (state is NavigateToPasses) {
          final deps = AppDependencies.of(context);
          final userId = deps.cache.getData(key: CacheKeys.savingUserId) ?? '';
          Navigator.of(context)
              .pushReplacementNamed(Routes.passesScreen, arguments: "${userId}");
        } else if (state is NavigateToOTP) {
          final deps = AppDependencies.of(context);
          final phone = deps.cache.getData(key: CacheKeys.userPhoneNumber) ?? '';
          Navigator.of(context).pushReplacementNamed(Routes.signInPage);
          Navigator.of(context).pushNamed(
            Routes.otpPage,
            arguments: OtpPageArgs(
              email: phone,
              maskedEmail: maskPhoneNumber(phone),
              isComingFromSigningUp: true,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF008CFF),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ── Background image with blue tint overlay ──────────────────
            Image.asset(AppImages.welcome, fit: BoxFit.cover),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,

                  colors: [
                    Color(0x660044AA),
                    Color(0xBB002255),
                  ],
                ),
              ),
            ),

            // ── Centered content ─────────────────────────────────────────
            SafeArea(
              child: FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo circle
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.15),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.villa_rounded,
                            color: Colors.white,
                            size: 52,
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Brand name
                        const Text(
                          'ROSANA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 8,
                          ),
                        ),

                        const SizedBox(height: 6),

                        // Divider line
                        Container(
                          width: 48,
                          height: 2,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Sub-label
                        Text(
                          'Resort',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 18,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Bottom location tag ───────────────────────────────────────
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FadeTransition(
                  opacity: _fade,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on_rounded,
                            color: Colors.white.withOpacity(0.55), size: 13),
                        const SizedBox(width: 5),
                        Text(
                          'North Coast, Egypt',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.55),
                            fontSize: 12,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}