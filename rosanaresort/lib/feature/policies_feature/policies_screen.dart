// ============================================================
//  policy_screens.dart
//  شاشات الشروط والأحكام وسياسة الخصوصية لقرية روزانا
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/colors/app_color.dart';

// ── Shared scaffold wrapper ───────────────────────────────────────────────────

class _PolicyScaffold extends StatelessWidget {
  final String title;
  final String lastUpdated;
  final List<_PolicySection> sections;

  const _PolicyScaffold({
    required this.title,
    required this.lastUpdated,
    required this.sections
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.lightBackGroundColor,
      appBar: AppBar(
        backgroundColor: AppColor.primaryDeep,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20.sp),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18.sp)),
        centerTitle: true,
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(24.w),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColor.primaryDeep, AppColor.lightPrimaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.gavel_rounded, color: Colors.white, size: 40.sp),
                  SizedBox(height: 12.h),
                  Text(title, style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w800, color: Colors.white)),
                  SizedBox(height: 4.h),
                  Text('تاريخ آخر تحديث: $lastUpdated', style: TextStyle(fontSize: 12.sp, color: Colors.white.withOpacity(0.8))),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.all(16.w),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) => _PolicySectionCard(section: sections[index]),
                childCount: sections.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicySection {
  final String title;
  final String body;
  const _PolicySection({required this.title, required this.body});
}

class _PolicySectionCard extends StatelessWidget {
  final _PolicySection section;
  const _PolicySectionCard({required this.section});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16.r), border: Border.all(color: AppColor.borderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(section.title, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700, color: AppColor.primaryDeep)),
          SizedBox(height: 8.h),
          Text(section.body, style: TextStyle(fontSize: 13.sp, color: AppColor.lightGreyColor, height: 1.6)),
        ],
      ),
    );
  }
}

// ============================================================
//  Terms & Conditions Screen
// ============================================================

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  static const _sections = [
    _PolicySection(title: '1. شروط الأهلية والحساب', body: 'يقتصر استخدام هذا التطبيق على ملاك الوحدات بقرية روزانا أو المستأجرين المصرح لهم رسمياً من قِبل الإدارة. يتحمل صاحب الحساب المسؤولية الكاملة عن كافة الأنشطة والتصاريح التي تصدر من خلال حسابه، وعن صحة بيانات ومسميات الزوار المكتوبة.'),
    _PolicySection(title: '2. السياسة المالية وتفعيل الخدمة', body: 'تنبيه هام: يشترط لتفعيل خدمات التطبيق وإصدار تصاريح الدخول الإلكترونية أن تكون الوحدة مسددة للتجديد السنوي ومستحقات الصيانة الخاصة بالعام الحالي لدى إدارة حسابات القرية. ويتوقف التطبيق تلقائياً عن العمل للوحدات غير المسددة.'),
    _PolicySection(title: '3. الاستخدام العادل وحدود التصاريح', body: 'تحتفظ إدارة القرية بالحق في تحديد حد أقصى (Limit) لعدد التصاريح اليومية أو الأسبوعية المتاحة لكل وحدة لمنع الإغراق وتأمين السعة الاستيعابية لبوابات القرية. لا يجوز استخدام التطبيق لإصدار تصاريح دخول لجهات تجارية أو أفراد غير معلومين بغرض التربح أو تسهيل الدخول غير القانوني للقرية.'),
    _PolicySection(title: '4. التدابير الأمنية وصحة الموقع (GPS)', body: 'يحظر حظراً تاماً محاولة استخدام برامج تزييف الموقع (Mock Location) أو التلاعب بإشارات الـ GPS لإصدار تصاريح من خارج النطاق الجغرافي المحدد للقرية. في حال رصد النظام لأي محاولة تلاعب بالبيانات الأمنية أو تزوير المواقع، يحق لإدارة القرية إيقاف الحساب نهائياً واتخاذ الإجراءات القانونية اللازمة.'),
    _PolicySection(title: '5. المسؤولية القانونية', body: 'إدارة قرية روزانا ومطورو التطبيق غير مسؤولين عن أي أضرار ناتجة عن إساءة استخدام التطبيق من قبل المالك، أو إعطاء بيانات الدخول والـ OTP لأشخاص غير مصرح لهم.'),
    _PolicySection(title: '6. تعديل الشروط', body: 'تحتفظ إدارة القرية بالحق في تعديل أو تحديث هذه الشروط والأحكام في أي وقت بناءً على مقتضيات المصلحة الأمنية والتنظيمية للقرية، ويتم إشعار المستخدمين بأي تعديل من خلال التطبيق.'),
  ];

  @override
  Widget build(BuildContext context) {
    return const _PolicyScaffold(title: 'الشروط والأحكام', lastUpdated: '2026-06-19', sections: _sections);
  }
}

// ============================================================
//  Privacy Policy Screen
// ============================================================

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _sections = [
    _PolicySection(title: '1. البيانات التي نقوم بجمعها', body: 'بيانات الهوية والاتصال: الاسم الثلاثي، الرقم القومي، ورقم الهاتف. بيانات الموقع الجغرافي (GPS): للتحقق من وجودك الفعلي داخل النطاق المسموح به. بيانات الزوار: أسماء الزوار وصور مستندات تحقيق الشخصية. بيانات الجهاز: عنوان الـ IP ونوع النظام وبصمة الجهاز.'),
    _PolicySection(title: '2. كيف نستخدم بياناتك؟', body: 'التحقق من هوية صاحب الوحدة وصلاحية طلبه، تأمين بوابات القرية ومنع إصدار تصاريح عشوائية من خارج النطاق الجغرافي، وتقديم تقارير أمنية لإدارة القرية عند الحاجة.'),
    _PolicySection(title: '3. مشاركة البيانات مع أطراف ثالثة', body: 'نحن لا نقوم ببيع، أو المتاجرة، أو مشاركة بياناتك الشخصية أو بيانات زوارك مع أي جهات خارجية، وتظل كافة البيانات محفوظة بشكل آمن ومخصصة فقط للاستخدام الداخلي لمنظومة الأمن والحسابات.'),
    _PolicySection(title: '4. أمن وحفظ البيانات', body: 'نحن نطبق إجراءات أمنية تقنية وإدارية صارمة لحماية بياناتك من الوصول غير المصرح به. يتم تخزين الصور والملفات المرفوعة على خوادم محمية ومشفرة.'),
    _PolicySection(title: '5. موافقتك على السياسة', body: 'باستخدامك لهذا التطبيق، فإنك توافق صراحة على سياسة الخصوصية هذه وعلى صلاحيات جمع الموقع الجغرافي اللازمة لعمل المنظومة الأمنية.'),
  ];

  @override
  Widget build(BuildContext context) {
    return const _PolicyScaffold(title: 'سياسة الخصوصية', lastUpdated: '2026-06-19', sections: _sections);
  }
}