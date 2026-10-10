import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/l10n/app_locales.dart';
import 'package:rider_app/core/l10n/localization_setup.dart';
import 'package:rider_app/design/theme/app_theme.dart';
import 'package:rider_app/design/tokens/brand.dart';

/// Pumps [child] inside the app's real localization and theme setup.
///
/// [inScaffold] false is for widgets that are whole screens themselves.
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  Locale locale = AppLocales.arabic,
  bool dark = false,
  bool inScaffold = true,
  bool settle = true,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        locale: locale,
        supportedLocales: AppLocales.all,
        localizationsDelegates: appLocalizationsDelegates,
        theme: dark
            ? AppTheme.dark(Brand.lenda, locale)
            : AppTheme.light(Brand.lenda, locale),
        home: inScaffold ? Scaffold(body: child) : child,
      ),
    ),
  );

  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// A 390×844 phone screen, the design's reference size, so layouts that overflow on a
/// real phone fail the test.
void usePhoneScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}
