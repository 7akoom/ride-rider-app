import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/error/failure.dart';
import 'package:rider_app/core/error/failure_messages.dart';
import 'package:rider_app/core/error/result.dart';
import 'package:rider_app/core/l10n/app_locales.dart';
import 'package:rider_app/core/l10n/l10n.dart';
import 'package:rider_app/core/location/location_access.dart';
import 'package:rider_app/core/location/geo_point.dart';
import 'package:rider_app/design/map/app_map.dart';
import 'package:rider_app/features/booking/domain/entities/saved_place.dart';
import 'package:rider_app/features/booking/domain/entities/spot.dart';
import 'package:rider_app/features/booking/presentation/choose_ride/choose_ride_screen.dart';
import 'package:rider_app/features/booking/presentation/map_picker/map_picker_screen.dart';
import 'package:rider_app/features/booking/presentation/where_to/where_to_controller.dart';
import 'package:rider_app/features/booking/presentation/where_to/where_to_screen.dart';

import '../../../helpers/pump_app.dart';
import '../fakes.dart';

const _here = Spot(
  point: GeoPoint(36.19, 44.01),
  kind: SpotKind.currentLocation,
  title: 'Gulan Street',
);

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump(WhereToController.typingPause);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => AppMap.usePlaceholder = true);
  tearDown(() => AppMap.usePlaceholder = false);

  final l10n = lookupAppLocalizations(AppLocales.arabic);

  testWidgets('typing finds places; choosing the destination opens the ride choice',
      (tester) async {
    usePhoneScreen(tester);
    await pumpApp(
      tester,
      const WhereToScreen(start: WhereToStart(pickup: _here)),
      inScaffold: false,
      overrides: bookingFakes(places: FakePlaces(found: [spotNamed('Family Mall')])),
    );

    await _type(tester, 'Family');
    await tester.tap(find.text('Family Mall'));
    await tester.pumpAndSettle();

    expect(find.byType(ChooseRideScreen), findsOneWidget);
    expect(find.text(l10n.chooseRideOrder(l10n.vehicleEconomy)), findsOneWidget);
  });

  testWidgets('the pickup can be the rider\'s own position, asking for location first',
      (tester) async {
    usePhoneScreen(tester);
    final location = FakeLocation(current: LocationAccessStatus.denied);
    await pumpApp(
      tester,
      const WhereToScreen(start: WhereToStart(destination: _here)),
      inScaffold: false,
      overrides: bookingFakes(location: location, places: FakePlaces(address: 'Lebanese Village')),
    );

    // No pickup yet: its field is the one being filled, with "current location" first.
    await tester.tap(find.text(l10n.spotCurrentLocation));
    await tester.pumpAndSettle();

    expect(location.prompts, 1);
    expect(find.byType(ChooseRideScreen), findsOneWidget);
  });

  testWidgets('the current location row is only for the pickup', (tester) async {
    usePhoneScreen(tester);
    await pumpApp(
      tester,
      const WhereToScreen(start: WhereToStart(pickup: _here)),
      inScaffold: false,
      overrides: bookingFakes(),
    );

    expect(find.text(l10n.spotCurrentLocation), findsNothing);
  });

  testWidgets('nothing found says so in words', (tester) async {
    usePhoneScreen(tester);
    await pumpApp(
      tester,
      const WhereToScreen(start: WhereToStart(pickup: _here)),
      inScaffold: false,
      overrides: bookingFakes(),
    );

    await _type(tester, 'zzzz');

    expect(find.text(l10n.whereToNoResults), findsOneWidget);
  });

  testWidgets('a stop can be added, and only two', (tester) async {
    usePhoneScreen(tester);
    await pumpApp(
      tester,
      const WhereToScreen(start: WhereToStart(pickup: _here)),
      inScaffold: false,
      overrides: bookingFakes(places: FakePlaces(found: [spotNamed('Pharmacy')])),
    );

    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byTooltip(l10n.whereToAddStop));
      await tester.pumpAndSettle();
      await _type(tester, 'Pharm');
      await tester.tap(find.text('Pharmacy').last);
      await tester.pumpAndSettle();
    }

    expect(find.byTooltip(l10n.whereToAddStop), findsNothing);
  });

  testWidgets('the map picker returns the point under the pin', (tester) async {
    usePhoneScreen(tester);
    Spot? picked;

    await pumpApp(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () async => picked = await Navigator.of(context).push<Spot>(
            MaterialPageRoute(builder: (_) => const MapPickerScreen(start: GeoPoint(36.2, 44))),
          ),
          child: const SizedBox.square(dimension: 40),
        ),
      ),
      overrides: bookingFakes(places: FakePlaces(address: 'Citadel')),
    );

    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();
    expect(find.text('Citadel'), findsOneWidget);

    await tester.tap(find.text(l10n.mapPickerConfirm));
    await tester.pumpAndSettle();

    expect(picked?.title, 'Citadel');
    expect(picked?.kind, SpotKind.pinned);
  });

  testWidgets('the map picker map fills the screen width', (tester) async {
    usePhoneScreen(tester);
    await pumpApp(
      tester,
      const MapPickerScreen(start: GeoPoint(36.2, 44)),
      inScaffold: false,
      overrides: bookingFakes(),
    );
    await tester.pumpAndSettle();

    final screen = tester.getSize(find.byType(Scaffold).first);
    expect(tester.getSize(find.byType(AppMap)).width, screen.width);
  });

  testWidgets('search down: a human message, and the saved places stay', (tester) async {
    usePhoneScreen(tester);
    final places = FakePlaces();
    await pumpApp(
      tester,
      const WhereToScreen(start: WhereToStart(pickup: _here)),
      inScaffold: false,
      overrides: bookingFakes(
        places: places,
        saved: FakeSavedPlaces(Ok([savedPlace(SavedPlaceKind.home)])),
      ),
    );
    await tester.pumpAndSettle();

    places.failure = const ServerFailure();
    await _type(tester, 'Family');

    expect(find.text(l10n.whereToSearchUnavailable), findsOneWidget);
    expect(find.text(l10n.errorServer), findsNothing);
    expect(find.text(l10n.whereToSaved), findsOneWidget);
    expect(find.text(l10n.whereToOnMap), findsOneWidget);
  });

  testWidgets('no connection says so, not that search is down', (tester) async {
    usePhoneScreen(tester);
    await pumpApp(
      tester,
      const WhereToScreen(start: WhereToStart(pickup: _here)),
      inScaffold: false,
      overrides: bookingFakes(places: FakePlaces(failure: const NetworkFailure())),
    );

    await _type(tester, 'Family');

    expect(find.text(const NetworkFailure().message(l10n)), findsOneWidget);
    expect(find.text(l10n.whereToSearchUnavailable), findsNothing);
  });

  for (final locale in AppLocales.all) {
    testWidgets('where-to fits a phone: ${locale.languageCode}', (tester) async {
      usePhoneScreen(tester);
      await pumpApp(
        tester,
        const WhereToScreen(start: WhereToStart(pickup: _here)),
        locale: locale,
        inScaffold: false,
        overrides: bookingFakes(
          places: FakePlaces(popular: [spotNamed('A rather long popular place name here')]),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  }
}
