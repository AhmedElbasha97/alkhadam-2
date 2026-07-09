import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/colors/app_color.dart';

class OtpDigitBox extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isFilled;
  final bool isError;
  final bool isActive;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspace;

  const OtpDigitBox({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isFilled,
    required this.isError,
    required this.isActive,
    required this.onChanged,
    required this.onBackspace,
  });

  @override
  State<OtpDigitBox> createState() => _OtpDigitBoxState();
}

class _OtpDigitBoxState extends State<OtpDigitBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceCtrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(begin: 1, end: 1.12).animate(
      CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeOutBack),
    );
  }

  @override
  void didUpdateWidget(OtpDigitBox old) {
    super.didUpdateWidget(old);
    if (!old.isFilled && widget.isFilled) {
      _bounceCtrl.forward().then((_) => _bounceCtrl.reverse());
    }
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    Color bgColor;

    if (widget.isError) {
      borderColor = const Color(0xFFFF4757);
      bgColor = const Color(0xFFFF4757).withOpacity(0.08);
    } else if (widget.isFilled) {
      borderColor = AppColor.lightPrimaryColor;
      bgColor = AppColor.lightPrimaryColor.withOpacity(0.08);
    } else if (widget.isActive) {
      borderColor = AppColor.lightPrimaryColor;
      bgColor = Colors.white;
    } else {
      borderColor = const Color(0xFFE0E0E0);
      bgColor = const Color(0xFFF8F8F8);
    }

    return ScaleTransition(
      scale: _scale,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44.w,
        height: 55.h,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: borderColor,
            width: widget.isActive || widget.isFilled ? 2 : 1.2,
          ),
          boxShadow: (widget.isActive || widget.isFilled) && !widget.isError
              ? [
            BoxShadow(
              color: AppColor.lightPrimaryColor.withOpacity(0.18),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ]
              : widget.isError
              ? [
            BoxShadow(
              color: const Color(0xFFFF4757).withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ]
              : [],
        ),
        child: KeyboardListener(
          focusNode: FocusNode(skipTraversal: true),
          onKeyEvent: (event) {
            if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.backspace &&
                widget.controller.text.isEmpty) {
              widget.onBackspace();
            }
          },
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            // NO maxLength — lets full paste string flow to onChanged
            obscureText: false,
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w800,
              color: widget.isError
                  ? const Color(0xFFFF4757)
                  : AppColor.lightSecondaryColor,
              height: 1,
            ),
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: widget.onChanged,
          ),
        ),
      ),
    );
  }
}