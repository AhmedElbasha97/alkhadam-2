import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/cache/cache_keys.dart';
import '../../../core/dependencies/app_dependencies.dart';
abstract class SplashState {}

class SplashInitial extends SplashState {}
class SplashLoading extends SplashState {}
class NavigateToOnboarding extends SplashState {}
class NavigateToLogin extends SplashState {}
class NavigateToOTP extends SplashState {}
class NavigateToPasses extends SplashState {}



class SplashCubit extends Cubit<SplashState> {
  SplashCubit() : super(SplashInitial());

  void initializeApp(BuildContext context) async {
    emit(SplashLoading());
    // Simulate initial asset caching or local storage checking
    await Future.delayed(const Duration(seconds: 3));

    // For demonstration, we assume it's the user's first time opening the app
    bool isFirstTime = true;
    final deps = AppDependencies.of(context);
    final onBoardingDone = deps.cache.getData(
        key: CacheKeys.onboardingDone) ?? false;
    final isInGuestMode = deps.cache.getData(key: CacheKeys.isGuest) ??
        false;
    final isUserInRegistratioOtp = deps.cache.getData(
        key: CacheKeys.isRegisterAndNotVerified) ?? false;
    final isUserRegistiredAndVerified = deps.cache.checkForData(
        key: CacheKeys.savingUserId) ;



    if (onBoardingDone) {
      emit(NavigateToOnboarding());
    } else  if(isUserInRegistratioOtp) {
      emit(NavigateToOTP());
    } else{
      emit(NavigateToLogin());
    }
  }
}