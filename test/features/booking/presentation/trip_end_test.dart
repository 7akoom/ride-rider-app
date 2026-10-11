import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/error/result.dart';
import 'package:rider_app/core/format/money_format.dart';
import 'package:rider_app/core/l10n/app_locales.dart';
import 'package:rider_app/core/l10n/l10n.dart';
import 'package:rider_app/design/map/app_map.dart';
import 'package:rider_app/features/booking/domain/entities/ride.dart';
import 'package:rider_app/features/booking/presentation/trip_end/rate_screen.dart';
import 'package:rider_app/features/booking/presentation/trip_end/trip_done_controller.dart';
import 'package:rider_app/features/booking/presentation/trip_end/trip_done_screen.dart';

import '../../../helpers/pump_app.dart';
import '../fakes.dart';

const _tick = Duration(milliseconds: 100);

Future<void> _wait(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(milliseconds: 600));
}

Future<void> _open(
  WidgetTester tester,
  Widget screen, {
  FakeTripEnd? tripEnd,
  FakeRides? rides,
  Locale? locale,
}) async {
  usePhoneScreen(tester);
  await pumpApp(
    tester,
    screen,
    locale: locale ?? AppLocales.arabic,
    inScaffold: false,
    settle: false,
    overrides: [
      ...bookingFakes(tripEnd: tripEnd, rides: rides),
      paymentCheckIntervalProvider.overrideWithValue(_tick),
    ],
  );
  await _wait(tester);
}

void main() {
  setUp(() => AppMap.usePlaceholder = true);
  tearDown(() => AppMap.usePlaceholder = false);

  final l10n = lookupAppLocalizations(AppLocales.arabic);
  final done = rideOf(status: RideStatus.completed);

  testWidgets('the summary shows what to pay the captain once the trip is settled',
      (tester) async {
    await _open(tester, TripDoneScreen(ride: done), tripEnd: FakeTripEnd(settleAfter: 2));

    expect(find.text(l10n.tripDoneTitle), findsOneWidget);
    expect(find.text(l10n.tripDonePayCash(formatMoney(l10n, 3000))), findsOneWidget);
    expect(find.text(someCaptain.name), findsOneWidget);
    expect(find.text(l10n.tripDoneReceipt), findsOneWidget);
  });

  testWidgets('a settlement that never comes says the fare shows later', (tester) async {
    await _open(tester, TripDoneScreen(ride: done), tripEnd: FakeTripEnd(paid: null));
    for (var i = 0; i < 4; i++) {
      await _wait(tester);
    }

    expect(find.text(l10n.tripDoneFareLater), findsOneWidget);
  });

  testWidgets('stars and a tip go together, then the thanks', (tester) async {
    final tripEnd = FakeTripEnd();
    await _open(tester, RateScreen(ride: done, captain: someCaptain), tripEnd: tripEnd);

    await tester.tap(find.byIcon(Icons.star_outline_rounded).at(4));
    await _wait(tester);
    await tester.tap(find.text(formatMoney(l10n, 1000)));
    await _wait(tester);
    await tester.tap(find.text(l10n.rateSend));
    await _wait(tester);

    expect(tripEnd.ratings.single.$1, 5);
    expect(tripEnd.tips.single, (1000, 'tip-trip-1'));
    expect(find.text(l10n.thanksTip(formatMoney(l10n, 1000))), findsOneWidget);
  });

  testWidgets('a tip above the wallet is stopped before it is sent', (tester) async {
    final tripEnd = FakeTripEnd();
    await _open(
      tester,
      RateScreen(ride: done, captain: someCaptain),
      tripEnd: tripEnd,
      rides: FakeRides(balance: const Ok(700)),
    );

    await tester.tap(find.text(formatMoney(l10n, 2000)));
    await _wait(tester);
    await tester.tap(find.text(l10n.rateSend));
    await _wait(tester);

    expect(tripEnd.tips, isEmpty);
    expect(find.text(l10n.tipNotEnough), findsOneWidget);
  });

  for (final locale in AppLocales.all) {
    testWidgets('the summary and the rating fit a phone: ${locale.languageCode}', (tester) async {
      await _open(tester, TripDoneScreen(ride: done), locale: locale);
      expect(tester.takeException(), isNull);

      await _open(tester, RateScreen(ride: done, captain: someCaptain), locale: locale);
      expect(tester.takeException(), isNull);
    });
  }
}
