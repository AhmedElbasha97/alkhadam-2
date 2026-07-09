// ignore_for_file: use_build_context_synchronously

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../cache/cache_consumer_impl.dart';

class LocalizationCubit extends Cubit<Locale> {
  final EncryptedCacheConsumerImpl storage;

  static const Locale defaultLocale = Locale('en');

  LocalizationCubit(this.storage) : super(defaultLocale);

  Future<void> loadLocale(BuildContext context) async {
    final code = storage.getSavedLocaleCode();
    final newLocale =
    (code != null && code.isNotEmpty) ? Locale(code) : defaultLocale;

    emit(newLocale);
    await context.setLocale(newLocale);
  }

  Future<void> toggleLanguage(BuildContext context,String? lang) async {
    final newCode = lang!=""? lang  :(storage.getSavedLocaleCode() == 'en' ? 'ar' : 'en');
    final newLocale = Locale(newCode??"");
    await storage.saveLocaleCode(newCode??"");
    await context.setLocale(newLocale);

    emit(newLocale);
  }

  /// 👇 New helper function
  String localizedText({
    required String en,
    required String ar,
  }) {
    return state.languageCode == 'ar' ? ar : en;
  }

  /// Optional helper (sometimes useful)
  bool  isArabic ()  {
    final code = storage.getSavedLocaleCode();
    return (code == 'ar'??true);
  }
}
