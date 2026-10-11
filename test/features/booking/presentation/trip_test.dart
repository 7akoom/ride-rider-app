import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/l10n/app_locales.dart';
import 'package:rider_app/core/l10n/l10n.dart';
import 'package:rider_app/core/share/share_text.dart';
import 'package:rider_app/design/map/app_map.dart';
import 'package:rider_app/features/booking/domain/entities/cancellation.dart';
import 'package:rider_app/features/booking/domain/entities/ride.dart';
import 'package:rider_app/features/booking/presentation/trip/trip_controller.dart';
import 'package:rider_app/features/booking/presentation/trip/trip_screen.dart';

import '../../../helpers/pump_app.dart';
import '../fakes.dart';

const _tick = Duration(milliseconds: 100);

/// The skeleton and the waiting time never settle: time is moved on by hand.
Future<void> _wait(WidgetTester tester, [Duration time = const Duration(milliseconds: 600)]) async {
  await tester.pump(time);
  await tester.pump(time);
}

Future<void> _open(
  WidgetTester tester,
  Ride ride, {
  FakeRides? rides,
  FakeCaptains? captains,
  FakeSafety? safety,
  List<String>? shared,
  Locale? locale,
}) async {
  usePhoneScreen(tester);
  await pumpApp(
    tester,
    TripScreen(ride: ride),
    locale: locale ?? AppLocales.arabic,
    inScaffold: false,
    settle: false,
    overrides: [
      ...bookingFakes(
        rides: (rides ?? FakeRides())..state ??= ride,
        captains: captains,
        safety: safety,
      ),
      tripCheckIntervalProvider.overrideWithValue(_tick),
      shareTextProvider.overrideWithValue((text) async => shared?.add(text)),
    ],
  );
  await _wait(tester);
}

void main() {
  setUp(() => AppMap.usePlaceholder = true);
  tearDown(() => AppMap.usePlaceholder = false);

  final l10n = lookupAppLocalizations(AppLocales.arabic);
  final coming = rideOf(status: RideStatus.accepted);

  testWidgets('the captain on the way: who, how long, the ride; cancelling asks first',
      (tester) async {
    final rides = FakeRides();
    await _open(tester, coming, rides: rides);

    expect(find.text(l10n.tripComingLabel), findsOneWidget);
    expect(find.text(l10n.etaMinutes(12)), findsOneWidget);
    expect(find.text(someCaptain.name), findsOneWidget);
    expect(find.text(someCaptain.car), findsOneWidget);
    expect(find.text('Family Mall'), findsOneWidget);

    // The sheet is dragged up, as the rider would, to reach the button at its end.
    await tester.drag(find.text(l10n.tripComingLabel), const Offset(0, -400));
    await _wait(tester);
    await tester.ensureVisible(find.text(l10n.tripCancel));
    await _wait(tester);
    await tester.tap(find.text(l10n.tripCancel));
    await _wait(tester);
    expect(find.text(l10n.cancelWhyTitle), findsOneWidget);
    expect(rides.cancelled, isEmpty);

    await tester.tap(find.text(l10n.cancelReasonLate));
    await _wait(tester);
    await tester.tap(find.text(l10n.tripCancel).last);
    await _wait(tester);

    expect(rides.cancelled, ['trip-1']);
    expect(rides.reasons.single?.reason, CancelReason.captainLate);
    expect(find.text(l10n.tripCancelled), findsOneWidget);
  });

  testWidgets('before the captain is located, the time is being worked out', (tester) async {
    await _open(tester, coming, captains: FakeCaptains(at: null));

    expect(find.text(l10n.tripComingSoon), findsOneWidget);
  });

  testWidgets('at the pickup: the captain is here, waiting since they arrived', (tester) async {
    final arrived = rideOf(
      status: RideStatus.accepted,
      arrivedAt: DateTime.now().subtract(const Duration(minutes: 2)),
    );
    await _open(tester, arrived);

    expect(find.text(l10n.tripArrivedTitle), findsOneWidget);
    expect(find.textContaining('2:0'), findsOneWidget);
    expect(find.text(l10n.tripCancel), findsOneWidget);
  });

  testWidgets('on the trip: when it arrives and what is left; no cancelling', (tester) async {
    await _open(tester, rideOf(status: RideStatus.onTrip));

    expect(find.text(l10n.tripArrivalLabel), findsOneWidget);
    expect(find.text(l10n.tripRemaining(l10n.etaMinutes(12))), findsOneWidget);
    expect(find.text(l10n.tripCancel), findsNothing);
  });

  testWidgets('a captain who cancels the ride is said in words',
      (tester) async {
    final rides = FakeRides();
    await _open(tester, coming, rides: rides);

    rides.state = rideOf(status: RideStatus.cancelled, byCaptain: true);
    await _wait(tester);

    expect(find.text(l10n.tripCancelledByCaptain), findsOneWidget);
  });

  testWidgets('another reason needs words before the ride is cancelled', (tester) async {
    final rides = FakeRides();
    await _open(tester, coming, rides: rides);
    await tester.drag(find.text(l10n.tripComingLabel), const Offset(0, -400));
    await _wait(tester);
    await tester.ensureVisible(find.text(l10n.tripCancel));
    await tester.tap(find.text(l10n.tripCancel));
    await _wait(tester);

    await tester.tap(find.text(l10n.cancelReasonOther));
    await _wait(tester);
    await tester.ensureVisible(find.text(l10n.tripCancel).last);
    await tester.tap(find.text(l10n.tripCancel).last);
    await _wait(tester);

    expect(find.text(l10n.cancelOtherEmpty), findsOneWidget);
    expect(rides.cancelled, isEmpty);
  });

  testWidgets('the safety centre shares the trip and sends the alarm', (tester) async {
    final safety = FakeSafety();
    final shared = <String>[];
    await _open(tester, rideOf(status: RideStatus.onTrip), safety: safety, shared: shared);

    await tester.tap(find.byIcon(Icons.shield_outlined));
    await _wait(tester);
    expect(find.text(l10n.safetyTitle), findsOneWidget);

    await tester.tap(find.text(l10n.safetyShare));
    await _wait(tester);
    expect(shared, [l10n.safetyShareMessage('https://ride.example/t/abc')]);
    expect(find.text(l10n.safetyStopShare), findsOneWidget);

    await tester.ensureVisible(find.text(l10n.safetySosSend));
    await tester.tap(find.text(l10n.safetySosSend));
    await _wait(tester);
    await tester.tap(find.text(l10n.safetySosConfirmYes));
    await _wait(tester);

    expect(safety.calls, ['share', 'alarm']);
    expect(find.text(l10n.safetySosSent), findsOneWidget);
  });

  testWidgets('without a page for shared trips, the centre says sharing is not available',
      (tester) async {
    final shared = <String>[];
    await _open(tester, coming, safety: FakeSafety(link: null), shared: shared);

    await tester.tap(find.byIcon(Icons.shield_outlined));
    await _wait(tester);
    await tester.tap(find.text(l10n.safetyShare));
    await _wait(tester);

    expect(shared, isEmpty);
    expect(find.text(l10n.safetyShareUnavailable), findsOneWidget);
  });

  for (final locale in AppLocales.all) {
    testWidgets('every stage fits a phone: ${locale.languageCode}', (tester) async {
      for (final ride in [
        coming,
        rideOf(status: RideStatus.accepted, arrivedAt: DateTime.now()),
        rideOf(status: RideStatus.onTrip),
      ]) {
        await _open(tester, ride, rides: FakeRides()..state = ride, locale: locale);
        expect(tester.takeException(), isNull);
      }
    });
  }
}
