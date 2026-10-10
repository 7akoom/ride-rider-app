import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/l10n/app_locales.dart';
import 'package:rider_app/design/design_context.dart';
import 'package:rider_app/design/fonts/app_fonts.dart';
import 'package:rider_app/design/theme/app_theme.dart';
import 'package:rider_app/design/tokens/brand.dart';

void main() {
  for (final locale in AppLocales.all) {
    for (final dark in [false, true]) {
      final mode = dark ? 'dark' : 'light';

      testWidgets('${locale.languageCode}/$mode theme exposes the tokens', (tester) async {
        final theme = dark
            ? AppTheme.dark(Brand.lenda, locale)
            : AppTheme.light(Brand.lenda, locale);
        late BuildContext captured;

        await tester.pumpWidget(MaterialApp(
          theme: theme,
          home: Builder(builder: (context) {
            captured = context;
            return const SizedBox.shrink();
          }),
        ));

        final expectedFamily = AppFonts.forLocale(locale).family;

        expect(captured.palette.brand, Brand.lenda.fill);
        expect(captured.typo.body.fontFamily, expectedFamily);
        expect(theme.brightness, dark ? Brightness.dark : Brightness.light);
        expect(theme.scaffoldBackgroundColor, captured.palette.background);
      });
    }
  }

  test('Arabic and Kurdish use the Arabic-script font, English the Latin one', () {
    expect(AppFonts.forLocale(AppLocales.arabic).family, AppFonts.arabic);
    expect(AppFonts.forLocale(AppLocales.kurdish).family, AppFonts.arabic);
    expect(AppFonts.forLocale(AppLocales.english).family, AppFonts.latin);
  });
}
