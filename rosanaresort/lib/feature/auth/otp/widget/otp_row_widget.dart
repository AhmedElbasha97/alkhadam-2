import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'otp_text_field.dart';

class OtpInputRow extends StatefulWidget {
  final int length;
  final bool isError;
  final List<String> digits;
  final ValueChanged<int> onDigitChanged;
  final VoidCallback onCompleted;
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;

  const OtpInputRow({
    super.key,
    required this.length,
    required this.isError,
    required this.digits,
    required this.onDigitChanged,
    required this.onCompleted,
    required this.controllers,
    required this.focusNodes,
  });

  @override
  State<OtpInputRow> createState() => _OtpInputRowState();
}

class _OtpInputRowState extends State<OtpInputRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeCtrl;
  late final Animation<double> _shakeAnim;

  // Clipboard watcher — fires every 500ms while page is open
  Timer? _clipboardTimer;
  String _lastClipboard = '';
  int _activeFocus = 0;

  @override
  void initState() {
    super.initState();

    // ── Shake animation ──────────────────────────────────────────────────────
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));

    // ── Focus listeners ──────────────────────────────────────────────────────
    for (int i = 0; i < widget.focusNodes.length; i++) {
      final index = i;
      widget.focusNodes[index].addListener(() {
        if (!mounted) return;
        if (widget.focusNodes[index].hasFocus) {
          setState(() => _activeFocus = index);
        }
      });
    }

  }

  void _startClipboardWatcher() {
    _clipboardTimer = Timer.periodic(const Duration(milliseconds: 1000), (_) {
      _checkClipboard();
    });
  }

  Future<void> _checkClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data == null || data.text == null) return;
      final raw = data.text!.trim();
      if (raw == _lastClipboard) return;
      final digits = raw.replaceAll(RegExp(r'\D'), '');
      if (digits.length >= widget.length) {
        _lastClipboard = raw;
        if (mounted) _distributePaste(digits);
      }
    } catch (_) {}
  }

  @override
  void didUpdateWidget(OtpInputRow old) {
    super.didUpdateWidget(old);
    if (!old.isError && widget.isError) {
      _shakeCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _clipboardTimer?.cancel();
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _onChanged(int index, String value) {
    if (value.isEmpty) return;
    if (value.length > 1) {
      _distributePaste(value);
      return;
    }
    widget.onDigitChanged(index);
    if (index < widget.length - 1) {
      widget.focusNodes[index + 1].requestFocus();
      setState(() => _activeFocus = index + 1);
    } else {
      widget.focusNodes[index].unfocus();
      widget.onCompleted();
    }
  }

  // ── Core distribute logic ────────────────────────────────────────────────
  void _distributePaste(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;

    for (int i = 0; i < widget.length; i++) {
      final char = i < digits.length ? digits[i] : '';
      widget.controllers[i].text = char;
      if (char.isNotEmpty) widget.onDigitChanged(i);
    }

    final lastFilled = (digits.length - 1).clamp(0, widget.length - 1);

    if (digits.length >= widget.length) {
      widget.focusNodes[lastFilled].unfocus();
      setState(() => _activeFocus = lastFilled);
    } else {
      widget.focusNodes[lastFilled + 1].requestFocus();
      setState(() => _activeFocus = lastFilled + 1);
    }
  }

  // ── Backspace on empty → go back ─────────────────────────────────────────
  void _onBackspace(int index) {
    if (index > 0) {
      widget.controllers[index - 1].clear();
      widget.focusNodes[index - 1].requestFocus();
      widget.onDigitChanged(index - 1);
      setState(() => _activeFocus = index - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (_, child) => Transform.translate(
        offset: Offset(_shakeAnim.value, 0),
        child: child,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(widget.length, (i) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 5.w),
            child: OtpDigitBox(
              controller: widget.controllers[i],
              focusNode: widget.focusNodes[i],
              isFilled: widget.digits[i].isNotEmpty,
              isError: widget.isError,
              isActive: _activeFocus == i && widget.focusNodes[i].hasFocus,
              onChanged: (val) => _onChanged(i, val),
              onBackspace: () => _onBackspace(i),
            ),
          );
        }),
      ),
    );
  }
}