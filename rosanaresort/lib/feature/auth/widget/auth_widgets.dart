import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

import '../../../core/theme/colors/app_color.dart';
import '../../../core/theme/images/app_images.dart';
import '../../../core/theme/styles/app_styles.dart';
import '../../../core/theme/transelation/localization_cubit.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Auth AppBar
// ─────────────────────────────────────────────────────────────────────────────
class AuthAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final bool showBack;

  const AuthAppBar({
    super.key,
    this.actionLabel,
    this.onActionTap,
    this.showBack = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leadingWidth: 100.w,
      backgroundColor: const Color(0xFF003A70),
      title: Text(actionLabel??"",
      style: AppStyles.price(context).add(
        color: AppColor.whiteTextColor,

      ),
      ),
      centerTitle: true,
      leading:    Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.h),
        child:  SvgPicture.asset(                      context.read<LocalizationCubit>().isArabic()?AppImages.whiteARLogoImage:AppImages.whiteLogoImage,
          width: 80.w,color: AppColor.whiteTextColor,),
      ),
      actions:[ IconButton(onPressed: (){
        Navigator.pop(context);
      }, icon:Icon( Icons.arrow_forward_ios_rounded,color: AppColor.whiteTextColor,size: 24.sp,)),],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}


class AuthTextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool obscureText;
  final IconData prefixIcon;
  final Widget? suffixIcon;
  final TextInputAction textInputAction;
  final FocusNode? focusNode;
  final void Function(String)? onFieldSubmitted;

  const AuthTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    required this.prefixIcon,
    this.suffixIcon,
    this.textInputAction = TextInputAction.next,
    this.focusNode,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppStyles.price(context).add(
            color: AppColor.lightSecondaryColor,
            size: 14.sp,
            weight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          obscureText: obscureText,
          textInputAction: textInputAction,
          focusNode: focusNode,
          onFieldSubmitted: onFieldSubmitted,

          style: AppStyles.price(context).add(
            color: AppColor.lightSecondaryColor,
            size: 14.sp,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintTextDirection: context.read<LocalizationCubit>().isArabic()?TextDirection.rtl:TextDirection.ltr,
            hintStyle:AppStyles.caption(context).add(
              color: Colors.grey.shade400,
              size: 14.sp,
            ),
            // Leading icon on the left
            prefixIcon: Icon(
              prefixIcon,
              color: Colors.grey.shade400,
              size: 20,
            ),
            // Toggle icon on the right (for password)
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.grey.shade100,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(
                  color: AppColor.lightPrimaryColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide:
                  const BorderSide(color: Colors.redAccent, width: 1.2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide:
                  const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
            errorStyle: TextStyle(
              fontSize: 11.sp,
              color: Colors.redAccent,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Password visibility toggle icon button
// ─────────────────────────────────────────────────────────────────────────────
class PasswordToggleIcon extends StatelessWidget {
  final bool obscure;
  final VoidCallback onTap;

  const PasswordToggleIcon({
    super.key,
    required this.obscure,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: Colors.grey.shade400,
        size: 20,
      ),
    );
  }
}
class AuthButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const AuthButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52.h,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColor.lightPrimaryColor,
          disabledBackgroundColor: AppColor.lightPrimaryColor.withOpacity(0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                label,
                style: AppStyles.caption(context).add(
                  color: AppColor.whiteTextColor,
                  size: 16.sp,
                  weight: FontWeight.w800,
                ),
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom prompt: "ليس لديك حساب? إنشاء حساب"
// ─────────────────────────────────────────────────────────────────────────────
class AuthBottomPrompt extends StatelessWidget {
  final String message;
  final String actionLabel;
  final VoidCallback onTap;

  const AuthBottomPrompt({
    super.key,
    required this.message,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          message,
          style:AppStyles.caption(context).add(
            color: AppColor.lightSecondaryColor,
            size: 14.sp,
          ),
        ),
        SizedBox(width: 4.w),
        GestureDetector(
          onTap: onTap,
          child: Text(
            actionLabel,
            style: AppStyles.caption(context).add(
              color: AppColor.lightPrimaryColor,
              size: 14.sp,
              weight: FontWeight.w700,
              decoration: TextDecoration.underline,
              decorationColor: AppColor.lightPrimaryColor,
            ),
          ),
        ),

      ],
    );
  }
}
class AuthErrorBanner extends StatelessWidget {
  final String message;

  const AuthErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.red.shade200, width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Colors.redAccent, size: 18),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 12.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
