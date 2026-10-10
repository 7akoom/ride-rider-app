import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/l10n/app_locales.dart';
import 'package:rider_app/design/components/components.dart';

import '../../helpers/pump_app.dart';

// A translation much longer than the space left must shorten, never overflow.
void main() {
  final longLabel = List.filled(12, 'word').join(' ');

  for (final locale in AppLocales.all) {
    testWidgets('long action label fits: ${locale.languageCode}', (tester) async {
      usePhoneScreen(tester);

      await pumpApp(
        tester,
        ListView(
          children: [
            StatusBanner(
              tone: Tone.danger,
              message: longLabel,
              actionLabel: longLabel,
              onAction: () {},
            ),
            SectionHeader(title: longLabel, actionLabel: longLabel, onAction: () {}),
          ],
        ),
        locale: locale,
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(EndActionRow), findsNWidgets(2));
    });
  }

  testWidgets('no action: only the content', (tester) async {
    await pumpApp(tester, const SectionHeader(title: 'x'));

    expect(find.byType(AppButton), findsNothing);
  });
}
