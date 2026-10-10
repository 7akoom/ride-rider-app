import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/l10n/app_locales.dart';
import 'package:rider_app/features/dev_gallery/presentation/gallery_screen.dart';
import 'package:rider_app/features/dev_gallery/presentation/sections/states_section.dart';

import '../../helpers/pump_app.dart';

// Builds every shared component on a phone-sized screen, in each language and mode,
// and scrolls through all of it: an overflow or a build error fails the test.
void main() {
  for (final locale in AppLocales.all) {
    for (final dark in [false, true]) {
      final mode = dark ? 'dark' : 'light';

      testWidgets('gallery renders cleanly: ${locale.languageCode}/$mode', (tester) async {
        usePhoneScreen(tester);

        await pumpApp(
          tester,
          const GalleryScreen(),
          locale: locale,
          dark: dark,
          inScaffold: false,
          settle: false,
        );

        await tester.dragUntilVisible(
          find.byType(StatesSection),
          find.byType(ListView),
          const Offset(0, -300),
        );
        await tester.pump(const Duration(milliseconds: 100));

        expect(tester.takeException(), isNull);
      });
    }
  }
}
