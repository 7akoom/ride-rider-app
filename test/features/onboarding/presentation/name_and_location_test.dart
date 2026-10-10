import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/error/failure.dart';
import 'package:rider_app/core/error/result.dart';
import 'package:rider_app/core/l10n/app_locales.dart';
import 'package:rider_app/core/l10n/l10n.dart';
import 'package:rider_app/design/components/components.dart';
import 'package:rider_app/features/onboarding/presentation/location/location_screen.dart';
import 'package:rider_app/features/onboarding/presentation/name/name_screen.dart';

import '../../../helpers/pump_app.dart';
import '../fakes.dart';

final _l10n = lookupAppLocalizations(AppLocales.arabic);

Finder _field(String label) => find.descendant(
      of: find.widgetWithText(AppTextField, label),
      matching: find.byType(TextField),
    );

void main() {
  group('name screen', () {
    Future<void> pumpName(WidgetTester tester, {FakeAccounts? accounts}) async {
      usePhoneScreen(tester);
      await pumpApp(
        tester,
        const NameScreen(),
        inScaffold: false,
        overrides: onboardingFakes(
          preferences: FakePreferences(locationShown: false),
          accounts: accounts,
        ),
      );
    }

    testWidgets('the button waits for a first name; a one-letter name is refused',
        (tester) async {
      await pumpName(tester);
      final button = find.widgetWithText(AppButton, _l10n.nameStart);
      expect(tester.widget<AppButton>(button).onPressed, isNull);

      await tester.enterText(_field(_l10n.fieldFirstName), 'a');
      await tester.pump();
      await tester.tap(button);
      await tester.pump();

      expect(find.text(_l10n.nameTooShort), findsOneWidget);
    });

    testWidgets('first and family name are saved, then the location screen', (tester) async {
      await pumpName(tester);

      await tester.enterText(_field(_l10n.fieldFirstName), 'Salem');
      await tester.enterText(_field(_l10n.fieldFamilyName), 'Suleiman');
      await tester.pump();
      await tester.tap(find.text(_l10n.nameStart));
      await tester.pumpAndSettle();

      expect(find.byType(LocationScreen), findsOneWidget);
    });

    testWidgets('a failed save is said in words', (tester) async {
      await pumpName(
        tester,
        accounts: FakeAccounts(const Ok(null), createFailure: const NetworkFailure()),
      );

      await tester.enterText(_field(_l10n.fieldFirstName), 'Salem');
      await tester.pump();
      await tester.tap(find.text(_l10n.nameStart));
      await tester.pumpAndSettle();

      expect(find.text(_l10n.errorNoConnection), findsOneWidget);
    });
  });

  for (final locale in AppLocales.all) {
    testWidgets('name and location screens fit a phone: ${locale.languageCode}',
        (tester) async {
      usePhoneScreen(tester);

      for (final screen in const [NameScreen(), LocationScreen()]) {
        await pumpApp(
          tester,
          screen,
          locale: locale,
          inScaffold: false,
          overrides: onboardingFakes(),
        );

        expect(tester.takeException(), isNull);
      }
    });
  }
}
