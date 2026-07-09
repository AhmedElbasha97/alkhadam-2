import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/models/pass_model.dart';
import 'pass_pdf_generator.dart';

class PassCard extends StatefulWidget {
  final PassModel pass;
  final int index;

  const PassCard({super.key, required this.pass, required this.index});

  @override
  State<PassCard> createState() => _PassCardState();
}

class _PassCardState extends State<PassCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final Animation<double> _entryFade;
  late final Animation<Offset> _entrySlide;

  bool _isExpanded = false;
  bool _isSavingQr = false;

  // Key used to capture the QR widget as an image
  final GlobalKey _qrKey = GlobalKey();

  static const _blue = Color(0xFF008CFF);
  static const _dark = Color(0xFF003A70);

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 280 + widget.index * 70),
    )..forward();
    _entryFade =
        CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entrySlide = Tween<Offset>(
      begin: const Offset(0, 0.14),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  // ── Save QR code as image and share ──────────────────────────────────────
  Future<void> _saveQrCode() async {
    setState(() => _isSavingQr = true);
    try {
      // Fetch QR image bytes from API
      final qrUrl =
          'https://api.qrserver.com/v1/create-qr-code/?size=400x400&data=${Uri.encodeComponent(widget.pass.qrcode)}';
      final response = await http.get(Uri.parse(qrUrl));
      if (response.statusCode != 200) throw Exception('QR fetch failed');

      final qrBytes = response.bodyBytes;

      // Save to temp dir
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/qr_${widget.pass.id}_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(qrBytes);

      // Share / save via share_plus (lets user save to gallery or share)
      if (mounted) {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'تصريح دخول — ${widget.pass.name}\nكود: ${widget.pass.caption}',
          subject: 'QR تصريح روزانا',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذّر حفظ QR: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r)),
            margin: EdgeInsets.all(14.w),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingQr = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.pass.isActive;

    return SlideTransition(
      position: _entrySlide,
      child: FadeTransition(
        opacity: _entryFade,
        child: GestureDetector(
          onTap: () { if(isActive){

            setState(() => _isExpanded = !_isExpanded);}
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            margin: EdgeInsets.only(bottom: 14.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: isActive
                    ? _blue.withOpacity(0.35)
                    : const Color(0xFFB3D4FF),
                width: isActive ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isActive
                      ? _blue.withOpacity(0.08)
                      : Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // ── Top info row ─────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.all(14.w),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PersonAvatar(
                          imgUrl: widget.pass.img, isActive: isActive),
                      SizedBox(width: 14.w),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name row + expand toggle
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.pass.name,
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w800,
                                      color: _dark,
                                    ),
                                  ),
                                ),
                                isActive?AnimatedRotation(
                                  turns: _isExpanded ? 0.5 : 0,
                                  duration: const Duration(milliseconds: 260),
                                  child: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: const Color(0xFF90C4FF),
                                    size: 22.sp,
                                  ),
                                ):SizedBox(),
                              ],
                            ),
                            SizedBox(height: 5.h),

                            // Caption
                            _InfoRow(
                              icon: Icons.confirmation_number_outlined,
                              text: widget.pass.caption,
                              color: _blue,
                            ),
                            SizedBox(height: 5.h),

                            // Dates
                            _InfoRow(
                              icon: Icons.calendar_today_outlined,
                              text:
                              '${widget.pass.dateFrom}  ←  ${widget.pass.dateTo}',
                              color: const Color(0xFF4A6080),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8.w),

                      _StatusBadge(isActive: isActive),
                    ],
                  ),
                ),

                // ── Expanded QR panel ────────────────────────────────────
                AnimatedCrossFade(
                  firstChild: const SizedBox(width: double.infinity),
                  secondChild: _QrPanel(pass: widget.pass, qrKey: _qrKey),
                  crossFadeState: _isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 270),
                ),

                // ── Action buttons ───────────────────────────────────────
                isActive? _ActionsBar(
                  pass: widget.pass,
                  isSavingQr: _isSavingQr,
                  onCopy: () {
                    Clipboard.setData(
                        ClipboardData(text: widget.pass.qrcode));
                    HapticFeedback.selectionClick();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(children: [
                          Icon(Icons.check_circle_rounded,
                              color: Colors.white, size: 16),
                          SizedBox(width: 8),
                          Text('تم نسخ الكود'),
                        ]),
                        backgroundColor: const Color(0xFF00C47A),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r)),
                        margin: EdgeInsets.all(14.w),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  onSaveQr: _saveQrCode,
                  onPdf: () => PassPdfGenerator.generateAndOpen(widget.pass),
                ):SizedBox(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── QR panel shown when expanded ─────────────────────────────────────────────
class _QrPanel extends StatelessWidget {
  final PassModel pass;
  final GlobalKey qrKey;

  const _QrPanel({required this.pass, required this.qrKey});

  static const _blue = Color(0xFF008CFF);

  @override
  Widget build(BuildContext context) {
    final qrUrl =
        'https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=${Uri.encodeComponent(pass.qrcode)}';

    return Container(
      margin: EdgeInsets.fromLTRB(14.w, 0, 14.w, 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F6FF),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          // QR image
          RepaintBoundary(
            key: qrKey,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: Image.network(
                qrUrl,
                width: 160.w,
                height: 160.w,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return SizedBox(
                    width: 160.w,
                    height: 160.w,
                    child: Center(
                      child: CircularProgressIndicator(
                          color: _blue, strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => Container(
                  width: 160.w,
                  height: 160.w,
                  color: const Color(0xFFE3EEFF),
                  child: Icon(Icons.qr_code_2_rounded,
                      size: 60.sp,
                      color: const Color(0xFF4A6080)),
                ),
              ),
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            'امسح الكود للتحقق',
            style: TextStyle(
              fontSize: 11.sp,
              color: const Color(0xFF4A6080),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 12.h),

          // Details rows
          _DetailRow(label: 'رقم التصريح', value: pass.caption, isBlue: true),
          Divider(height: 14.h, color: const Color(0xFFB3D4FF)),
          _DetailRow(label: 'من', value: pass.dateFrom),
          Divider(height: 14.h, color: const Color(0xFFB3D4FF)),
          _DetailRow(label: 'إلى', value: pass.dateTo),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBlue;
  const _DetailRow(
      {required this.label, required this.value, this.isBlue = false});

  static const _blue = Color(0xFF008CFF);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12.sp, color: const Color(0xFF4A6080))),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: isBlue ? _blue : const Color(0xFF003A70),
            letterSpacing: isBlue ? 0.5 : 0,
          ),
        ),
      ],
    );
  }
}

// ── Actions bar ───────────────────────────────────────────────────────────────
class _ActionsBar extends StatelessWidget {
  final PassModel pass;
  final bool isSavingQr;
  final VoidCallback onCopy;
  final VoidCallback onSaveQr;
  final VoidCallback onPdf;

  static const _blue = Color(0xFF008CFF);

  const _ActionsBar({
    required this.pass,
    required this.isSavingQr,
    required this.onCopy,
    required this.onSaveQr,
    required this.onPdf,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F6FF),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20.r),
          bottomRight: Radius.circular(20.r),
        ),
      ),
      padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 12.h),
      child: Column(
        children: [
          // Row 1 — PDF  |  Copy QR text
          Row(
            children: [
              _Btn(
                icon: Icons.picture_as_pdf_rounded,
                label: 'تحميل PDF',
                isPrimary: true,
                onTap: onPdf,
              ),


            ],
          ),
          SizedBox(height: 8.h),

          // Row 2 — Save QR image (full width)
          _SaveQrButton(isSaving: isSavingQr, onTap: onSaveQr),
        ],
      ),
    );
  }
}

// ── Save QR button ────────────────────────────────────────────────────────────
class _SaveQrButton extends StatelessWidget {
  final bool isSaving;
  final VoidCallback onTap;

  static const _blue = Color(0xFF008CFF);

  const _SaveQrButton({required this.isSaving, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isSaving ? null : () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 11.h),
        decoration: BoxDecoration(
          color: isSaving
              ? const Color(0xFF005AB5).withOpacity(0.7)
              : const Color(0xFF003A70),
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: isSaving
              ? []
              : [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSaving)
              SizedBox(
                width: 16.w,
                height: 16.w,
                child: const CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            else
              Icon(Icons.qr_code_rounded, color: _blue, size: 18.sp),
            SizedBox(width: 8.w),
            Text(
              isSaving ? 'جارٍ الحفظ...' : 'حفظ كود QR كصورة',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared action button ──────────────────────────────────────────────────────
class _Btn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  static const _blue = Color(0xFF008CFF);

  const _Btn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: isPrimary ? _blue : Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isPrimary ? _blue : const Color(0xFFB3D4FF),
            ),
            boxShadow: isPrimary
                ? [
              BoxShadow(
                color: _blue.withOpacity(0.28),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16.sp,
                  color:
                  isPrimary ? Colors.white : const Color(0xFF4A6080)),
              SizedBox(width: 6.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: isPrimary ? Colors.white : const Color(0xFF003A70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Person avatar ─────────────────────────────────────────────────────────────
class _PersonAvatar extends StatelessWidget {
  final String imgUrl;
  final bool isActive;
  static const _blue = Color(0xFF008CFF);

  const _PersonAvatar({required this.imgUrl, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 70.w,
          height: 70.w,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isActive ? _blue.withOpacity(0.5) : Colors.transparent,
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14.r),
            child: Image.network(
              imgUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFFE3EEFF),
                child: Icon(Icons.person_rounded,
                    color: const Color(0xFF4A6080), size: 32.sp),
              ),
            ),
          ),
        ),
        if (isActive)
          Positioned(
            bottom: 3.h,
            right: 3.w,
            child: Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                color: const Color(0xFF00C47A),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final bool isActive;
  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFF00C47A).withOpacity(0.1)
            : const Color(0xFFE3EEFF),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isActive
              ? const Color(0xFF00C47A).withOpacity(0.3)
              : const Color(0xFF90C4FF),
          width: 1,
        ),
      ),
      child: Text(
        isActive ? 'فعّال' : 'منتهي',
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
          color: isActive
              ? const Color(0xFF00C47A)
              : const Color(0xFF4A6080),
        ),
      ),
    );
  }
}

// ── Info row ──────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _InfoRow(
      {required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13.sp, color: color),
        SizedBox(width: 4.w),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12.sp,
              color: color,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
