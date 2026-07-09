import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/colors/app_color.dart';
import '../../../../core/theme/styles/app_styles.dart';
import '../../../../core/theme/transelation/localization_key.dart';

class ResendTimerWidget extends StatelessWidget {
  final int seconds;
  final bool canResend;
  final bool isResending;
  final VoidCallback onResend;

  const ResendTimerWidget({
    super.key,
    required this.seconds,
    required this.canResend,
    required this.isResending,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Countdown ring
        if (!canResend && !isResending) ...[
          SizedBox(
            width: 56.w,
            height: 56.w,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background ring
                SizedBox(
                  width: 56.w,
                  height: 56.w,
                  child: CircularProgressIndicator(
                    value: 1,
                    strokeWidth: 3,
                    color: AppColor.whiteTextColor,
                  ),
                ),
                // Animated progress
                SizedBox(
                  width: 56.w,
                  height: 56.w,
                  child: CircularProgressIndicator(
                    value: seconds / 60,
                    strokeWidth: 3,
                    color: AppColor.lightPrimaryColor,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                // Seconds text
                Text(
                  '$seconds',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColor.lightSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            '${TranslationKey.otpVerificationResendText.tr()} $seconds ${TranslationKey.secondKey.tr()}',
            style: AppStyles.price(context).add(
              color: AppColor.lightGreyColor,
              size: 13.sp,
            ),
          ),
        ],

        if (canResend&&!isResending)
          GestureDetector(
            onTap: onResend,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: AppColor.lightPrimaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30.r),
                border: Border.all(
                  color: AppColor.lightPrimaryColor.withOpacity(0.4),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.refresh_rounded,
                    color: AppColor.lightPrimaryColor,
                    size: 18,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    TranslationKey.otpVerificationBTNResendTitle.tr(),
                    style: AppStyles.price(context).add(
                      color: AppColor.lightPrimaryColor,
                      size: 14.sp,
                      weight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),

        if (isResending) ...[
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColor.lightPrimaryColor,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
    TranslationKey.otpVerificationText.tr(),
            style: AppStyles.body(context).add(
              color: AppColor.lightGreyColor,
              size: 13.sp,
            ),
          ),
        ],
      ],
    );
  }
}