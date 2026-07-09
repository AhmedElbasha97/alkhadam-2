// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rosanaresort/config/routes/routes.dart';
import 'package:rosanaresort/feature/add_passes/feature/add_passes_screen.dart';
import 'package:rosanaresort/feature/on_boarding/page/on_boarding_screen.dart';
import 'package:rosanaresort/feature/passes/data/datasources/passes_remote_datasource.dart';
import 'package:rosanaresort/feature/passes/data/repositories/passes_repository.dart';
import '../../core/dependencies/app_dependencies.dart';
import '../../core/theme/colors/app_color.dart';
import '../../feature/auth/log_in/pages/login_page.dart';
import '../../feature/auth/otp/presentation/Otp_screen.dart';
import '../../feature/passes/presentation/cubit/passes_cubit.dart';
import '../../feature/passes/presentation/pages/passes_screen.dart';
import '../../feature/policies_feature/policies_screen.dart';
import '../../feature/profile_feature/feature/cubit/profile_cubit.dart';
import '../../feature/profile_feature/feature/page/profile_page.dart';
import '../../feature/splash_screen/page/splash_screen.dart';



class RoutesManager {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Route<dynamic>? generateRoute(RouteSettings settings) {
    late Widget screen;

    switch (settings.name) {
      case Routes.splashScreen:
        screen = const SplashScreen();
        break;
      case Routes.onboardingScreen:
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (_, __, ___) => const OnboardingScreen(),
          transitionDuration: const Duration(milliseconds: 1000),
          transitionsBuilder: (_, animation, __, child) {
            // Fades in the onboarding screen
            return FadeTransition(
              opacity: animation,
              // Slightly scales up the skyscrapers for a "zoom" effect
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
                ),
                child: child,
              ),
            );
          },
        );
      case Routes.otpPage:

        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (_, __, ___) {
            final args = settings.arguments as OtpPageArgs;

            return OtpPage(args: OtpPageArgs(email: args.email, maskedEmail: args.maskedEmail,otpLength: 6,isComingFromSigningUp: args.isComingFromSigningUp),);},
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        );
      case Routes.passesScreen:
          // pass un_id via Navigator.pushNamed
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (_, __, ___) {
            final String unId = "${settings.arguments}";
          return PassesScreen(unId: unId);
          },
          transitionDuration: const Duration(milliseconds: 1000),
          transitionsBuilder: (_, animation, __, child) {
            // Fades in the onboarding screen
            return FadeTransition(
              opacity: animation,
              // Slightly scales up the skyscrapers for a "zoom" effect
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
                ),
                child: child,
              ),
            );
          },
        );
      case Routes.signInPage:

        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (_, __, ___) =>  SignInPage(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        );
    // ── Profile ────────────────────────────────────────────────────────────
      case Routes.drawerProfilePage:
      case Routes.profilePage:
        return MaterialPageRoute(
          builder: (ctx) => BlocProvider(
            create: (_) => ProfileCubit(
              api: AppDependencies.of(ctx).api,
              cache: AppDependencies.of(ctx).cache,
            )..loadProfile(),
            child: const ProfileScreen(),
          ),
        );
        // ── Profile ────────────────────────────────────────────────────────────
      case Routes.addPasses:
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (_, __, ___) =>  AddPassScreen(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        );

    // ── Policy screens ─────────────────────────────────────────────────────
      case Routes.privacyPolicyPage:
        return MaterialPageRoute(
          builder: (_) => const PrivacyPolicyScreen(),
        );

      case Routes.termsPage:
        return MaterialPageRoute(
          builder: (_) => const TermsScreen(),
        );
      default:
        screen = _undefinedRouteScreen();
        break;
    }
    return MaterialPageRoute(settings: settings, builder: (_) => screen);
  }

  static AppDependencies? _getDeps() {
    final context = navigatorKey.currentContext;
    if (context == null) return null;
    return AppDependencies.of(context);
  }

  static Widget _undefinedRouteScreen() {
    return Scaffold(
      appBar: AppBar(backgroundColor: AppColor.lightBackGroundColor,),
      backgroundColor: AppColor.lightBackGroundColor,
      body: Center(
        child: Text("data"),
      ),
    );
  }
}
