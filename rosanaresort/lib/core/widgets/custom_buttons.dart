import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import '../theme/colors/app_color.dart';

/// Shared button styles: filled, outline, text. Supports optional icon and asset image.
class CustomButtons {
  CustomButtons._();

  static Widget _buttonChild({
    required String text,
    required TextStyle textStyle,
    bool showIcon = false,
    IconData? icon,
    bool showImage = false,
    String? imagePath,
    MainAxisAlignment alignment = MainAxisAlignment.center,
    Color? iconColor,
    bool isEnabled = true,
    bool isSvg = false,
  }) {
    final resolvedStyle = isEnabled
        ? textStyle
        : textStyle.copyWith(color: AppColor.lightPrimaryColor);

    if (!showIcon && !showImage) {
      return Center(child: Text(text, style: resolvedStyle));
    }

    const double iconSize = 20;
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: alignment,
      children: [
        Flexible(
          child: Text(
            text,
            style: resolvedStyle,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (showIcon) ...[
          if (text.isNotEmpty) SizedBox(width: 6.w),
          Icon(
            icon,
            color:
                iconColor ??
                (isEnabled
                    ? AppColor.whiteTextColor
                    : AppColor.lightGreyColor),
            size: iconSize,
          ),
        ],
        if (showImage && (imagePath != null && imagePath.isNotEmpty)) ...[
          if (showIcon) SizedBox(width: 4.w) else SizedBox(width: 6.w),
          isSvg
              ? SvgPicture.asset(
                  imagePath,
                  width: 18.w,
                  height: 18.h,
                  fit: BoxFit.contain,
                  colorFilter: ColorFilter.mode(
                    isEnabled
                        ? (iconColor ?? AppColor.whiteTextColor)
                        : AppColor.lightGreyColor,
                    BlendMode.srcIn,
                  ),
                )
              : Image.asset(imagePath, width: 18.w, height: 18.h),
        ],
      ],
    );
  }

  static Widget filledButton({
    required double height,
    required double width,
    bool isEnabled = true,
    required VoidCallback onPressed,
    required String text,
    required TextStyle textStyle,
    bool showIcon = false,
    IconData? icon,
    Color? iconColor,
    bool showImage = false,
    String? imagePath,
    MainAxisAlignment alignment = MainAxisAlignment.center,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
    Color buttonColor = AppColor.lightPrimaryColor,
    bool isSvg = false,
  }) {
    return SizedBox(
      height: height,
      width: width,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          disabledBackgroundColor: AppColor.lightGreyColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: padding,
        ),
        child: _buttonChild(
          text: text,
          textStyle: textStyle,
          showIcon: showIcon,
          icon: icon,
          showImage: showImage,
          imagePath: imagePath,
          iconColor: isEnabled ? iconColor : AppColor.lightGreyColor,
          alignment: alignment,
          isEnabled: isEnabled,
          isSvg: isSvg,
        ),
      ),
    );
  }

  static Widget outlineButton({
    required double height,
    required double width,
    bool isEnabled = true,
    required VoidCallback onPressed,
    required String text,
    required TextStyle textStyle,
    bool showIcon = false,
    IconData? icon,
    Color? iconColor,
    bool showImage = false,
    String? imagePath,
    MainAxisAlignment alignment = MainAxisAlignment.center,
    Color buttonColor = AppColor.lightPrimaryColor,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
    bool isSvg = false,
  }) {
    return SizedBox(
      height: height,
      width: width,
      child: OutlinedButton(
        onPressed: isEnabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          side: isEnabled
              ? BorderSide(color: buttonColor)
              : BorderSide(color: AppColor.lightGreyColor),
          // backgroundColor: buttonColor,
          disabledBackgroundColor: AppColor.lightGreyColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: padding,
        ),
        child: _buttonChild(
          text: text,
          textStyle: textStyle,
          showIcon: showIcon,
          icon: icon,
          showImage: showImage,
          imagePath: imagePath,
          iconColor: isEnabled ? iconColor : AppColor.lightGreyColor,
          alignment: alignment,
          isEnabled: isEnabled,
        ),
      ),
    );
  }

  static Widget textButton({
    required double width,
    bool isEnabled = true,
    required VoidCallback onPressed,
    required String text,
    required TextStyle textStyle,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
  }) {
    return SizedBox(
      width: width,
      child: TextButton(
        onPressed: isEnabled ? onPressed : null,
        style: TextButton.styleFrom(
          padding: padding,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: textStyle.copyWith(
            decorationColor: AppColor.lightPrimaryColor,
          ),
        ),
      ),
    );
  }
}
