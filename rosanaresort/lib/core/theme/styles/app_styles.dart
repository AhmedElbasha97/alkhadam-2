// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:tires/core/constants/app_constants.dart';

// import '../colors/app_color.dart';

// class AppStyles {
//   const AppStyles._();

//   static String _getFontFamily(BuildContext context) {
//     final locale = Localizations.localeOf(context).languageCode;

//     if (locale == 'ar') {
//       return StringsManager.arabicFamily;
//     } else {
//       return StringsManager.englishFamily;
//     }
//   }

//   static TextStyle _baseStyle({
//     required BuildContext context,
//     required double fontSize,
//     required FontWeight fontWeight,
//     required Color color,
//   }) {
//     return TextStyle(
//       fontSize: fontSize.sp,
//       fontWeight: fontWeight,
//       fontFamily: _getFontFamily(context),
//       color: color,
//     );
//   }

//   static TextStyle heading1(BuildContext context) => _baseStyle(
//     context: context,
//     fontSize: 24,
//     fontWeight: FontWeight.w700,
//     color: AppColor.lightTextColor,
//   );

//   static TextStyle heading2(BuildContext context) => _baseStyle(
//     context: context,
//     fontSize: 20,
//     fontWeight: FontWeight.w800,
//     color: AppColor.lightTextColor,
//   );

//   static TextStyle sectionTitle(BuildContext context) => _baseStyle(
//     context: context,
//     fontSize: 18,
//     fontWeight: FontWeight.w600,
//     color: AppColor.lightTextColor,
//   );

//   static TextStyle subtitle(BuildContext context) => _baseStyle(
//     context: context,
//     fontSize: 14,
//     fontWeight: FontWeight.w500,
//     color: AppColor.lightGreyTextColor,
//   );

//   static TextStyle body(BuildContext context) => _baseStyle(
//     context: context,
//     fontSize: 14,
//     fontWeight: FontWeight.w400,
//     color: AppColor.lightTextColor,
//   );

//   static TextStyle bodySmall(BuildContext context) => _baseStyle(
//     context: context,
//     fontSize: 12,
//     fontWeight: FontWeight.w400,
//     color: AppColor.lightGreyTextColor,
//   );

//   static TextStyle caption(BuildContext context) => _baseStyle(
//     context: context,
//     fontSize: 11,
//     fontWeight: FontWeight.w400,
//     color: AppColor.lightGreyTextColor,
//   );

//   static TextStyle price(BuildContext context) => _baseStyle(
//     context: context,
//     fontSize: 16,
//     fontWeight: FontWeight.w700,
//     color: AppColor.lightPrimaryColor,
//   );

//   static TextStyle buttonTextPrimary(BuildContext context) => _baseStyle(
//     context: context,
//     fontSize: 14,
//     fontWeight: FontWeight.w700,
//     color: Colors.white,
//   );

//   static TextStyle buttonTextSecondary(BuildContext context) => _baseStyle(
//     context: context,
//     fontSize: 14,
//     fontWeight: FontWeight.w700,
//     color: AppColor.lightPrimaryColor,
//   );
// }
// //
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../constants/app_constants.dart';
import '../colors/app_color.dart';

class AppStyles {
  const AppStyles._();

  // ─── Font family resolution ───────────────────────────────────────────────

  static String _getFontFamily(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return locale == 'ar'
        ? StringsManager
              .arabicFamily // 'Almarai'
        : StringsManager.englishFamily;
  }

  // ─── Base builder ─────────────────────────────────────────────────────────

  static TextStyle _baseStyle({
    required BuildContext context,
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double? height,
    double? letterSpacing,
    String? fontFamily,
  }) {
    return TextStyle(
      fontSize: fontSize.sp,
      fontWeight: fontWeight,
      fontFamily: fontFamily ?? _getFontFamily(context),
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  // ─── Headings ─────────────────────────────────────────────────────────────

  static TextStyle heading1(BuildContext context) => _baseStyle(
    context: context,
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColor.lightSecondaryColor,
  );

  static TextStyle heading2(BuildContext context) => _baseStyle(
    context: context,
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: AppColor.lightSecondaryColor,
  );

  static TextStyle sectionTitle(BuildContext context) => _baseStyle(
    context: context,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColor.lightSecondaryColor,
  );

  // ─── Body ─────────────────────────────────────────────────────────────────

  static TextStyle subtitle(BuildContext context) => _baseStyle(
    context: context,
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: AppColor.lightSecondaryColor,
    height: 1.5, // 150% line height
    letterSpacing: 0,
  );

  static TextStyle body(BuildContext context) => _baseStyle(
    context: context,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColor.lightSecondaryColor,
  );

  static TextStyle bodySmall(BuildContext context) => _baseStyle(
    context: context,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColor.lightSecondaryColor,
  );

  static TextStyle caption(BuildContext context) => _baseStyle(
    context: context,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColor.lightSecondaryColor,
  );

  // ─── Special ──────────────────────────────────────────────────────────────

  static TextStyle price(BuildContext context) => _baseStyle(
    context: context,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColor.lightPrimaryColor,
  );

  // ─── Buttons ──────────────────────────────────────────────────────────────

  static TextStyle buttonTextPrimary(BuildContext context) => _baseStyle(
    context: context,
    fontSize: 14.sp,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  static TextStyle buttonTextSecondary(BuildContext context) => _baseStyle(
    context: context,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColor.lightPrimaryColor,
  );
  static const TextStyle heading = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColor.lightSecondaryColor,
  );

  static const TextStyle subheading = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColor.lightGreyColor,
  );

  static const TextStyle fieldLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColor.lightGreyColor,
    letterSpacing: 0.3,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColor.lightSecondaryColor,
  );

  static const TextStyle bodyBold = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColor.lightSecondaryColor,
  );



  static const TextStyle stepActive = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
    color: AppColor.lightSecondaryColor,
  );

  static const TextStyle stepInactive = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
    color: AppColor.stepInactiveColor,
  );

  static const TextStyle priceMain = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColor.lightSecondaryColor,
  );

  static const TextStyle priceDay = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColor.lightGreyColor,
  );

  static const TextStyle totalPrice = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: AppColor.lightSecondaryColor,
  );
}

extension TextStyleExtension on TextStyle {
  TextStyle add({
    Color? color,
    double? size,
    FontWeight? weight,
    FontStyle? style,
    double? height,
    TextDecoration? decoration,
    Color? decorationColor,
    double?  letterSpacing
  }) {
    return copyWith(
      color: color,
      fontSize: size,
      fontWeight: weight,
      fontStyle: style,
      height: height,
      decoration: decoration,
      fontFamily: fontFamily,
      decorationColor: decorationColor,
        letterSpacing: letterSpacing
    );
  }
}
