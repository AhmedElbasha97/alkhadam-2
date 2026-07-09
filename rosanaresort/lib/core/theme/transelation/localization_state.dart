
import 'dart:ui';


abstract class LocalizationState { Locale get locale; }

class LocalizationLoaded extends LocalizationState { final Locale _locale; LocalizationLoaded(this._locale); @override Locale get locale => _locale; }
