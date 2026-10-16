import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/error/result.dart';
import 'package:rider_app/core/l10n/app_locales.dart';
import 'package:rider_app/core/l10n/l10n.dart';
import 'package:rider_app/core/location/location_access.dart';
import 'package:rider_app/design/map/app_map.dart';
import 'package:rider_app/features/booking/domain/entities/saved_place.dart';
import 'package:rider_app/features/booking/presentation/home/home_tab.dart';

import '../../../helpers/pump_app.dart';
import '../fakes.dart';

void main() {
  setUp(() => AppMap.usePlaceholder = true);
  tearDown(() => AppMap.usePlaceholder = false);

  final l10n = lookupAppLocalizations(AppLocales.arabic);

  testWidgets('the booking map: pickup, "Where to?" and saved places', (tester) async {
    usePhoneScreen(tester);
    await pumpApp(
      tester,
      const HomeTab(),
      overrides: bookingFakes(
        location: FakeLocation(current: LocationAccessStatus.granted),
        saved: FakeSavedPlaces(Ok([savedPlace(SavedPlaceKind.home)])),
      ),
    );

    expect(find.text(l10n.homeRide), findsOneWidget);
    expect(find.text(l10n.homePickupFrom('Gulan Street')), findsOneWidget);
    expect(find.text(l10n.savedHome), findsOneWidget);
    expect(find.text(l10n.homeLocationOff), findsNothing);
    expect(find.text(l10n.homeWhereTo), findsOneWidget);
  });

  testWidgets('opened from the home, it has a way back', (tester) async {
    usePhoneScreen(tester);
    await pumpApp(tester, const BookingMapScreen(), inScaffold: false, overrides: bookingFakes());

    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
  });

  testWidgets('location off: the notice, and "Turn on" asks', (tester) async {
    usePhoneScreen(tester);
    final location = FakeLocation();
    await pumpApp(tester, const HomeTab(), overrides: bookingFakes(location: location));

    expect(find.text(l10n.homeLocationOff), findsOneWidget);

    await tester.tap(find.text(l10n.homeLocationTurnOn));
    await tester.pumpAndSettle();

    expect(location.prompts, 1);
    expect(find.text(l10n.homeLocationOff), findsNothing);
  });

  for (final locale in AppLocales.all) {
    testWidgets('home fits a phone: ${locale.languageCode}', (tester) async {
      usePhoneScreen(tester);
      await pumpApp(
        tester,
        const HomeTab(),
        locale: locale,
        overrides: bookingFakes(
          saved: FakeSavedPlaces(Ok([
            savedPlace(SavedPlaceKind.home),
            savedPlace(SavedPlaceKind.work),
            savedPlace(SavedPlaceKind.other, label: 'A long saved place name'),
          ])),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  }
}
