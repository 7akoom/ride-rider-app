import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/error/result.dart';
import 'package:rider_app/core/format/money_format.dart';
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

  testWidgets('greets the rider by first name; pickup and saved places', (tester) async {
    usePhoneScreen(tester);
    await pumpApp(
      tester,
      const HomeTab(),
      overrides: bookingFakes(
        location: FakeLocation(current: LocationAccessStatus.granted),
        saved: FakeSavedPlaces(Ok([savedPlace(SavedPlaceKind.home)])),
      ),
    );

    expect(find.textContaining('Salem'), findsOneWidget);
    expect(find.text(l10n.homePickupFrom('Gulan Street')), findsOneWidget);
    expect(find.text(l10n.savedHome), findsOneWidget);
    expect(find.text(l10n.homeLocationOff), findsNothing);
    expect(find.text(l10n.homeWhereTo), findsOneWidget);
    expect(find.text(l10n.walletTitle), findsOneWidget);
    expect(find.text(formatMoney(l10n, 12500)), findsOneWidget);
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
