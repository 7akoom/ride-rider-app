import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/error/failure.dart';
import 'package:rider_app/core/error/result.dart';
import 'package:rider_app/core/format/bidi.dart';
import 'package:rider_app/core/format/money_format.dart';
import 'package:rider_app/core/l10n/app_locales.dart';
import 'package:rider_app/core/l10n/l10n.dart';
import 'package:rider_app/core/location/location_access.dart';
import 'package:rider_app/design/map/app_map.dart';
import 'package:rider_app/features/booking/domain/entities/ride.dart';
import 'package:rider_app/features/booking/domain/entities/saved_place.dart';
import 'package:rider_app/features/home/presentation/home_screen.dart';
import 'package:rider_app/features/offers/domain/entities/offer.dart';
import 'package:rider_app/features/offers/presentation/offer_texts.dart';

import '../../helpers/pump_app.dart';
import '../booking/fakes.dart';

void main() {
  setUp(() => AppMap.usePlaceholder = true);
  tearDown(() => AppMap.usePlaceholder = false);

  final l10n = lookupAppLocalizations(AppLocales.arabic);

  Future<void> open(
    WidgetTester tester, {
    FakeRides? rides,
    FakeOffers? offers,
    FakeSavedPlaces? saved,
    FakeRecentDestinations? recent,
    FakeMoneyRequests? requests,
    FakeLocation? location,
    Locale locale = AppLocales.arabic,
  }) async {
    usePhoneScreen(tester);
    await pumpApp(
      tester,
      const HomeScreen(),
      locale: locale,
      overrides: bookingFakes(
        location: location ?? FakeLocation(current: LocationAccessStatus.granted),
        rides: rides,
        offers: offers,
        saved: saved,
        recent: recent,
        requests: requests,
      ),
    );
  }

  testWidgets('greets the rider; the services, the balance and their places', (tester) async {
    await open(
      tester,
      saved: FakeSavedPlaces(Ok([savedPlace(SavedPlaceKind.home), savedPlace(SavedPlaceKind.other, label: 'Gym')])),
      recent: FakeRecentDestinations(const Ok([familyMall])),
    );

    expect(find.textContaining('Salem'), findsOneWidget);
    expect(find.text(l10n.homeWhereTo), findsOneWidget);
    expect(find.text(l10n.homeRide), findsOneWidget);
    expect(find.text(l10n.homeSchedule), findsOneWidget);
    expect(find.text(l10n.walletTitle), findsOneWidget);
    expect(find.text(formatMoney(l10n, 12500)), findsOneWidget);
    expect(find.text(l10n.savedHome), findsOneWidget);
    expect(find.text('Gym'), findsNothing, reason: 'only home and work are shortcuts here');
    expect(find.text('Family Mall'), findsOneWidget);
    expect(find.text(l10n.homeLocationOff), findsNothing);
  });

  testWidgets('nothing from the server: no ride card, no offers, no last destination', (tester) async {
    await open(tester, recent: FakeRecentDestinations(const Err(ServerFailure())));

    expect(find.text(l10n.offersTitle), findsNothing);
    expect(find.text(l10n.homeLastTrip), findsNothing);
    expect(find.text(l10n.searchingTitle), findsNothing);
    expect(find.text(l10n.promoTitle), findsOneWidget, reason: 'a code can always be typed');
  });

  testWidgets('a ride under way shows on top, with the captain\'s car', (tester) async {
    await open(tester, rides: FakeRides(active: rideOf(status: RideStatus.accepted)));

    expect(find.text(l10n.tripComingLabel), findsOneWidget);
    expect(find.textContaining('22 A 25626'), findsOneWidget);
  });

  testWidgets('the ride card follows the ride without a refresh, and goes when it ends', (tester) async {
    final rides = FakeRides(active: rideOf());
    await open(tester, rides: rides);

    expect(find.text(l10n.searchingTitle), findsOneWidget);

    rides.active = rideOf(status: RideStatus.accepted);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(find.text(l10n.tripComingLabel), findsOneWidget);
    expect(find.textContaining('22 A 25626'), findsOneWidget);

    rides.active = rideOf(status: RideStatus.onTrip);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(find.text(l10n.tripOnTheWay), findsOneWidget);

    rides.active = null;
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(find.text(l10n.tripOnTheWay), findsNothing);
  });

  testWidgets('a ride still searching says so', (tester) async {
    await open(tester, rides: FakeRides(active: rideOf()));

    expect(find.text(l10n.searchingTitle), findsOneWidget);
  });

  testWidgets('waiting money requests show on the wallet tile', (tester) async {
    await open(tester, requests: FakeMoneyRequests(requests: [requestOf(), requestOf(code: 'K7XMQ2PQRY')]));

    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('location off: the notice on the home', (tester) async {
    await open(tester, location: FakeLocation());

    expect(find.text(l10n.homeLocationOff), findsOneWidget);
  });

  group('offers', () {
    final coupon = couponOf('SAVE30', description: 'Weekend rides');

    testWidgets('the first ride and the featured coupons', (tester) async {
      await open(
        tester,
        offers: FakeOffers(
          result: Ok(RiderOffers(coupons: [coupon], firstRide: const AutomaticOffer(percent: 50, maxAmount: 5000))),
        ),
      );

      expect(find.text(l10n.offersTitle), findsOneWidget);
      expect(find.text(l10n.offerFirstRideTitle('50')), findsOneWidget);
      expect(find.text(l10n.offerUpTo(formatMoney(l10n, 5000))), findsOneWidget);
      expect(find.text(l10n.offerPercent('30')), findsOneWidget);
      expect(find.text('Weekend rides'), findsOneWidget);
    });

    testWidgets('how far the loyalty discount is', (tester) async {
      await open(
        tester,
        offers: FakeOffers(
          result: const Ok(RiderOffers(
            loyalty: LoyaltyOffer(every: 5, percent: 20, completedTrips: 3, tripsToGo: 2),
          )),
        ),
      );

      expect(find.text(l10n.offerLoyaltyTitle('20', 5)), findsOneWidget);
      expect(find.text(l10n.offerLoyaltyToGo(2)), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('a coupon in full, kept for the next ride', (tester) async {
      final offers = FakeOffers(result: Ok(RiderOffers(coupons: [coupon])));
      await open(tester, offers: offers);

      await tester.tap(find.text('Weekend rides'));
      await tester.pumpAndSettle();

      for (final line in OfferTexts.conditions(l10n, coupon)) {
        expect(find.text(line), findsWidgets);
      }

      await tester.tap(find.text(l10n.offerUseNext));
      await tester.pumpAndSettle();

      expect(offers.kept, 'SAVE30');
      expect(find.text(l10n.offerKept(isolateLtr('SAVE30'))), findsWidgets);

      // The "kept" toast covers the bottom of the screen; it goes before the tap.
      tester.state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger)).removeCurrentSnackBar();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(l10n.couponRemove));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.couponRemove));
      await tester.pumpAndSettle();

      expect(offers.kept, isNull);
      expect(find.text(l10n.couponRemove), findsNothing);
    });
  });

  group('a typed promo code', () {
    testWidgets('is checked, upper case, and kept when the rider may use it', (tester) async {
      final offers = FakeOffers(checks: {'SAVE30': CodeCheckResult(CodeCheck.usable, couponOf('SAVE30'))});
      await open(tester, offers: offers);

      await tester.tap(find.text(l10n.promoTitle));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'save30');
      await tester.pump();
      await tester.tap(find.text(l10n.couponApply));
      await tester.pumpAndSettle();

      expect(offers.checked, ['SAVE30']);
      expect(offers.kept, 'SAVE30');
      expect(find.text(l10n.couponApply), findsNothing, reason: 'the sheet closed');
    });

    testWidgets('says why it cannot be used, and keeps nothing', (tester) async {
      final offers = FakeOffers(checks: {'OLD26': const CodeCheckResult(CodeCheck.expired)});
      await open(tester, offers: offers);

      await tester.tap(find.text(l10n.promoTitle));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'OLD26');
      await tester.pump();
      await tester.tap(find.text(l10n.couponApply));
      await tester.pumpAndSettle();

      expect(find.text(l10n.couponExpired), findsOneWidget);
      expect(offers.kept, isNull);
    });
  });

  for (final locale in AppLocales.all) {
    testWidgets('the home fits a phone with everything on it: ${locale.languageCode}', (tester) async {
      await open(
        tester,
        locale: locale,
        location: FakeLocation(),
        rides: FakeRides(active: rideOf(status: RideStatus.accepted)),
        saved: FakeSavedPlaces(Ok([savedPlace(SavedPlaceKind.home), savedPlace(SavedPlaceKind.work)])),
        recent: FakeRecentDestinations(const Ok([familyMall])),
        requests: FakeMoneyRequests(requests: [requestOf()]),
        offers: FakeOffers(
          kept: 'SAVE30',
          result: Ok(RiderOffers(
            coupons: [
              couponOf('SAVE30', description: 'A long description of the weekend offer for every rider in town'),
              couponOf('FLAT2000', kind: OfferDiscount.amount, value: 2000, maxDiscount: null),
            ],
            firstRide: const AutomaticOffer(percent: 50, maxAmount: 5000),
          )),
        ),
      );

      expect(tester.takeException(), isNull);

      await tester.drag(find.byType(ListView).first, const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  }
}
