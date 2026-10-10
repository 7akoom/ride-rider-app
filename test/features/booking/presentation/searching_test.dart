import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/l10n/app_locales.dart';
import 'package:rider_app/core/l10n/l10n.dart';
import 'package:rider_app/design/map/app_map.dart';
import 'package:rider_app/features/booking/domain/entities/ride.dart';
import 'package:rider_app/features/booking/presentation/searching/searching_controller.dart';
import 'package:rider_app/features/booking/presentation/searching/searching_screen.dart';

import '../../../helpers/pump_app.dart';
import '../fakes.dart';

const _tick = Duration(milliseconds: 100);

/// The pulse never settles: time is moved on by hand.
Future<void> _wait(WidgetTester tester, [Duration time = const Duration(milliseconds: 600)]) async {
  await tester.pump(time);
  await tester.pump(time);
}

Future<void> _open(WidgetTester tester, Ride ride, FakeRides rides, {Locale? locale}) async {
  usePhoneScreen(tester);
  await pumpApp(
    tester,
    SearchingScreen(ride: ride),
    locale: locale ?? AppLocales.arabic,
    inScaffold: false,
    settle: false,
    overrides: [
      ...bookingFakes(rides: rides),
      searchCheckIntervalProvider.overrideWithValue(_tick),
    ],
  );
  await _wait(tester);
}

void main() {
  setUp(() => AppMap.usePlaceholder = true);
  tearDown(() => AppMap.usePlaceholder = false);

  final l10n = lookupAppLocalizations(AppLocales.arabic);

  testWidgets('the ride shows while a captain is looked for; cancelling asks first',
      (tester) async {
    final rides = FakeRides();
    await _open(tester, rideOf(), rides);

    expect(find.text(l10n.searchingTitle), findsOneWidget);
    expect(find.text('Gulan Street'), findsOneWidget);
    expect(find.text('Family Mall'), findsOneWidget);

    await tester.tap(find.text(l10n.searchingCancel));
    await _wait(tester);
    expect(find.text(l10n.searchingCancelTitle), findsOneWidget);
    expect(rides.cancelled, isEmpty);

    await tester.tap(find.text(l10n.searchingCancelYes));
    await _wait(tester);

    expect(rides.cancelled, ['trip-1']);
    expect(find.text(l10n.searchingCancelled), findsOneWidget);
  });

  testWidgets('when the platform finds no captain, trying again searches again',
      (tester) async {
    final rides = FakeRides();
    await _open(tester, rideOf(), rides);

    rides.state = rideOf(noCaptain: true);
    await _wait(tester);
    expect(find.text(l10n.noCaptainTitle), findsOneWidget);

    rides.state = null;
    await tester.tap(find.text(l10n.actionRetry));
    await _wait(tester);

    expect(rides.orders, hasLength(1));
    expect(find.text(l10n.searchingTitle), findsOneWidget);
  });

  testWidgets('a ride opened after the search ran out offers another ride type',
      (tester) async {
    await _open(tester, rideOf(noCaptain: true), FakeRides());

    expect(find.text(l10n.noCaptainTitle), findsOneWidget);
    expect(find.text(l10n.noCaptainChange), findsOneWidget);
  });

  for (final locale in AppLocales.all) {
    testWidgets('searching and no captain fit a phone: ${locale.languageCode}', (tester) async {
      await _open(tester, rideOf(), FakeRides(), locale: locale);
      expect(tester.takeException(), isNull);

      await _open(tester, rideOf(noCaptain: true), FakeRides(), locale: locale);
      expect(tester.takeException(), isNull);
    });
  }
}
