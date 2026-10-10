import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_locales.dart';

// Flutter ships no Material/Cupertino texts for Kurdish Sorani. These delegates give the
// system widgets (date pickers, text selection menus, back button labels) their Arabic
// texts while the app speaks Kurdish, and with them the right-to-left direction.
// The app's own texts still come from app_ku.arb.

bool _isKurdish(Locale locale) =>
    locale.languageCode == AppLocales.kurdish.languageCode;

class KurdishMaterialFallbackDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const KurdishMaterialFallbackDelegate();

  @override
  bool isSupported(Locale locale) => _isKurdish(locale);

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      GlobalMaterialLocalizations.delegate.load(AppLocales.arabic);

  @override
  bool shouldReload(KurdishMaterialFallbackDelegate old) => false;
}

class KurdishCupertinoFallbackDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const KurdishCupertinoFallbackDelegate();

  @override
  bool isSupported(Locale locale) => _isKurdish(locale);

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      GlobalCupertinoLocalizations.delegate.load(AppLocales.arabic);

  @override
  bool shouldReload(KurdishCupertinoFallbackDelegate old) => false;
}

class KurdishWidgetsFallbackDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const KurdishWidgetsFallbackDelegate();

  @override
  bool isSupported(Locale locale) => _isKurdish(locale);

  @override
  Future<WidgetsLocalizations> load(Locale locale) =>
      GlobalWidgetsLocalizations.delegate.load(AppLocales.arabic);

  @override
  bool shouldReload(KurdishWidgetsFallbackDelegate old) => false;
}
