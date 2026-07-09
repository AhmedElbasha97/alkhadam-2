import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/styles/app_styles.dart';
import '../../passes/presentation/cubit/passes_cubit.dart';
import '../../passes/presentation/cubit/passes_state.dart';

class AddPassScreen extends StatefulWidget {
  const AddPassScreen({super.key});

  @override
  State<AddPassScreen> createState() => _AddPassScreenState();
}

class _AddPassScreenState extends State<AddPassScreen>
    with SingleTickerProviderStateMixin {
  static const _blue = Color(0xFF008CFF);
  static const _blueDeep = Color(0xFF0066CC);
  static const _dark = Color(0xFF003A70);
  static const _bg = Color(0xFFF4F8FF);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  final _nameFocus = FocusNode();
  final _notesFocus = FocusNode();

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  late final AnimationController _entryCtrl;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  bool _nameTouched = false;
  bool _imageTouched = false;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    )..forward();
    _fadeIn = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));

    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    _nameFocus.dispose();
    _notesFocus.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  // ── Progress: 3 steps — name, photo, (notes optional doesn't count) ────
  int get _completedSteps {
    int n = 0;
    if (_nameController.text.trim().isNotEmpty) n++;
    if (_selectedImage != null) n++;
    return n;
  }

  Future<void> _pickImage() async {
    HapticFeedback.selectionClick();
    setState(() => _imageTouched = true);
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() => _selectedImage = File(pickedFile.path));
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      _showSnack('حدث خطأ أثناء اختيار الصورة', isError: true);
    }
  }

  void _showSnack(String message, {bool isError = false, IconData? icon}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon ?? Icons.warning_amber_rounded, color: Colors.white, size: 20.sp),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(message,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp)),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade600 : Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
        margin: EdgeInsets.all(16.w),
      ),
    );
  }

  void _submitPass() {
    FocusScope.of(context).unfocus();
    setState(() => _nameTouched = true);

    if (!_formKey.currentState!.validate()) return;

    if (_selectedImage == null) {
      setState(() => _imageTouched = true);
      HapticFeedback.heavyImpact();
      _showSnack('يرجى إرفاق صورة الهوية للمتابعة');
      return;
    }

    context.read<PassesCubit>().storePass(
      name: _nameController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      image: _selectedImage!, context: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: BlocConsumer<PassesCubit, PassesState>(
        listenWhen: (_, current) =>
        current is StorePassSuccess || current is StorePassError,
        listener: (context, state) {
          if (state is StorePassSuccess) {
            Navigator.pop(context, true);
          } else if (state is StorePassError) {
            _showSnack(state.message, isError: true, icon: Icons.error_outline_rounded);
          }
        },
        builder: (context, state) {
          final isLoading = state is StorePassLoading;

          return Scaffold(
            backgroundColor: _bg,
            extendBodyBehindAppBar: false,
            appBar: _buildAppBar(isLoading),
            body: SafeArea(
              top: false,
              child: Stack(
                children: [
                  FadeTransition(
                    opacity: _fadeIn,
                    child: SlideTransition(
                      position: _slideUp,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 130.h),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildProgressBar(),
                              SizedBox(height: 20.h),
                              _buildInfoBanner(),
                              SizedBox(height: 24.h),
                              _buildSectionLabel(
                                title: 'اسم الزائر',
                                icon: Icons.badge_outlined,
                                isDone: _nameController.text.trim().isNotEmpty,
                              ),
                              SizedBox(height: 10.h),
                              _buildNameField(),
                              SizedBox(height: 22.h),
                              _buildSectionLabel(
                                title: 'ملاحظات',
                                subtitle: '(اختياري)',
                                icon: Icons.notes_rounded,
                                isDone: _notesController.text.trim().isNotEmpty,
                              ),
                              SizedBox(height: 10.h),
                              _buildNotesField(),
                              SizedBox(height: 26.h),
                              _buildSectionLabel(
                                title: 'صورة الهوية',
                                icon: Icons.credit_card_rounded,
                                isDone: _selectedImage != null,
                              ),
                              SizedBox(height: 10.h),
                              _buildImagePicker(isLoading),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  _buildBottomBar(isLoading),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── App bar ───────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(bool isLoading) {
    return AppBar(
      elevation: 0,
      centerTitle: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_dark, _blueDeep],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      systemOverlayStyle: SystemUiOverlayStyle.light,
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'إضافة تصريح جديد',
            style: AppStyles.price(context).add(
              color: Colors.white,
              size: 17.sp,
              weight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'سيتم إصدار التصريح فور التأكيد',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 11.sp,
            ),
          ),
        ],
      ),
      leading: Padding(
        padding: EdgeInsets.all(8.w),
        child: Material(
          color: Colors.white.withOpacity(0.12),
          shape: const CircleBorder(),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
            onPressed: isLoading ? null : () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }

  // ── Progress indicator ───────────────────────────────────────────────
  Widget _buildProgressBar() {
    final progress = _completedSteps / 2;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'اكتمال البيانات',
                      style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w700, color: _dark),
                    ),
                    const Spacer(),
                    Text(
                      '$_completedSteps / 2',
                      style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800, color: _blue),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20.r),
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                    tween: Tween(begin: 0, end: progress),
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 6.h,
                      backgroundColor: const Color(0xFFE6F0FF),
                      valueColor: const AlwaysStoppedAnimation(_blue),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Info banner ───────────────────────────────────────────────────────
  Widget _buildInfoBanner() {
    return Container(
      padding: EdgeInsets.all(15.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_blue.withOpacity(0.10), _blue.withOpacity(0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: _blue.withOpacity(0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Icon(Icons.info_outline_rounded, color: _blue, size: 18.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'يرجى التأكد من إدخال اسم الزائر وإرفاق صورة واضحة للهوية الشخصية لإصدار التصريح.',
              style: TextStyle(color: _dark, fontSize: 12.5.sp, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section label with done-check ────────────────────────────────────
  Widget _buildSectionLabel({
    required String title,
    required IconData icon,
    String? subtitle,
    bool isDone = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 17.sp, color: _dark.withOpacity(0.65)),
        SizedBox(width: 6.w),
        Text(title, style: TextStyle(fontSize: 14.5.sp, fontWeight: FontWeight.w800, color: _dark)),
        if (subtitle != null) ...[
          SizedBox(width: 4.w),
          Text(subtitle, style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade500)),
        ],
        const Spacer(),
        AnimatedOpacity(
          opacity: isDone ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: Icon(Icons.check_circle_rounded, size: 17.sp, color: Colors.green.shade400),
        ),
      ],
    );
  }

  // ── Name field ────────────────────────────────────────────────────────
  Widget _buildNameField() {
    final hasError = _nameTouched && _nameController.text.trim().isEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: _nameFocus.hasFocus
            ? [BoxShadow(color: _blue.withOpacity(0.15), blurRadius: 14, offset: const Offset(0, 4))]
            : [],
      ),
      child: TextFormField(
        controller: _nameController,
        focusNode: _nameFocus,
        onTap: () => setState(() {}),
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'أدخل الاسم الثلاثي للزائر',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14.sp),
          filled: true,
          fillColor: Colors.white,
          prefixIcon: Icon(Icons.person_outline_rounded,
              color: _nameFocus.hasFocus ? _blue : Colors.grey.shade400),
          suffixIcon: _nameController.text.trim().isNotEmpty
              ? Icon(Icons.check_circle_rounded, color: Colors.green.shade400, size: 20.sp)
              : null,
          contentPadding: EdgeInsets.symmetric(vertical: 16.h),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide(color: hasError ? Colors.red.shade300 : Colors.transparent),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: const BorderSide(color: _blue, width: 1.6),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.6),
          ),
        ),
        validator: (val) {
          if (val == null || val.trim().isEmpty) return 'يرجى إدخال اسم الزائر';
          return null;
        },
      ),
    );
  }

  // ── Notes field ───────────────────────────────────────────────────────
  Widget _buildNotesField() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: _notesFocus.hasFocus
            ? [BoxShadow(color: _blue.withOpacity(0.15), blurRadius: 14, offset: const Offset(0, 4))]
            : [],
      ),
      child: TextFormField(
        controller: _notesController,
        focusNode: _notesFocus,
        maxLines: 3,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'أضف رقم لوحة السيارة أو أي ملاحظات أخرى',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13.5.sp),
          filled: true,
          fillColor: Colors.white,
          alignLabelWithHint: true,
          prefixIcon: Padding(
            padding: EdgeInsets.only(bottom: 36.h),
            child: Icon(Icons.directions_car_filled_outlined,
                color: _notesFocus.hasFocus ? _blue : Colors.grey.shade400),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 14.h),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: const BorderSide(color: _blue, width: 1.6),
          ),
        ),
      ),
    );
  }

  // ── Image picker ──────────────────────────────────────────────────────
  Widget _buildImagePicker(bool isLoading) {
    final hasError = _imageTouched && _selectedImage == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: isLoading ? null : _pickImage,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            width: double.infinity,
            height: 160.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(
                color: hasError
                    ? Colors.red.shade300
                    : (_selectedImage == null ? Colors.grey.shade300 : _blue),
                width: _selectedImage == null ? 1.4 : 2,
              ),
              boxShadow: _selectedImage != null
                  ? [BoxShadow(color: _blue.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 6))]
                  : [],
            ),
            child: _selectedImage != null
                ? Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16.r),
                  child: Image.file(_selectedImage!, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 8.h,
                  left: 8.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 13.sp),
                        SizedBox(width: 4.w),
                        Text('تم الإرفاق',
                            style: TextStyle(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 8.h,
                  right: 8.w,
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 2,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: isLoading ? null : _pickImage,
                      child: Padding(
                        padding: EdgeInsets.all(7.w),
                        child: Icon(Icons.edit_rounded, size: 15.sp, color: _blue),
                      ),
                    ),
                  ),
                ),
              ],
            )
                : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: hasError ? Colors.red.withOpacity(0.08) : _blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.add_a_photo_outlined,
                      color: hasError ? Colors.red.shade400 : _blue, size: 26.sp),
                ),
                SizedBox(height: 12.h),
                Text(
                  'اضغط لإرفاق صورة الهوية',
                  style: TextStyle(
                    color: hasError ? Colors.red.shade400 : Colors.grey.shade600,
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'JPG, PNG — حتى 5 ميجابايت',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11.sp),
                ),
              ],
            ),
          ),
        ),
        if (_selectedImage != null) ...[
          SizedBox(height: 8.h),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: isLoading ? null : () => setState(() => _selectedImage = null),
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
              label: Text('حذف الصورة',
                  style: TextStyle(color: Colors.redAccent, fontSize: 12.5.sp, fontWeight: FontWeight.w600)),
              style: TextButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 4.w)),
            ),
          ),
        ],
      ],
    );
  }

  // ── Bottom sticky action bar ─────────────────────────────────────────
  Widget _buildBottomBar(bool isLoading) {
    final isReady = _completedSteps == 2;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 14.h),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, -6)),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            height: 54.h,
            child: ElevatedButton(
              onPressed: isLoading ? null : _submitPass,
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                disabledBackgroundColor: _blue.withOpacity(0.55),
                elevation: isReady ? 4 : 0,
                shadowColor: _blue.withOpacity(0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
              ),
              child: isLoading
                  ? SizedBox(
                width: 24.w,
                height: 24.w,
                child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'تأكيد وإصدار التصريح',
                    style: TextStyle(fontSize: 15.5.sp, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  SizedBox(width: 8.w),
                  Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18.sp),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}