import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/app/config_error_app.dart';
import 'package:rider_app/core/l10n/app_locales.dart';
import 'package:rider_app/core/l10n/l10n.dart';

// Boots a real MaterialApp with the app's localization setup in each language and checks
// the text and the reading direction, Kurdish included (it relies on the fallback
// delegates for Flutter's own widgets).
void main() {
  for (final locale in AppLocales.all) {
    testWidgets('speaks ${locale.languageCode} in the right direction', (tester) async {
      tester.platformDispatcher.localesTestValue = [locale];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);

      await tester.pumpWidget(const ConfigErrorApp());
      await tester.pumpAndSettle();

      final message = lookupAppLocalizations(locale).errorAppMisconfigured;
      final text = find.text(message);

      expect(text, findsOneWidget);
      expect(
        Directionality.of(tester.element(text)),
        AppLocales.directionOf(locale),
      );
    });
  }
}
