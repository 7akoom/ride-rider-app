import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../l10n/gen/app_localizations.dart';
import 'kurdish_fallback_delegates.dart';

/// The delegates every MaterialApp in this app uses.
///
/// The Kurdish fallbacks come first: for each type Flutter keeps the first delegate that
/// supports the locale.
const List<LocalizationsDelegate<dynamic>> appLocalizationsDelegates = [
  KurdishMaterialFallbackDelegate(),
  KurdishCupertinoFallbackDelegate(),
  KurdishWidgetsFallbackDelegate(),
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
];
