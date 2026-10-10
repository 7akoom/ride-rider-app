import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/error/failure.dart';
import 'package:rider_app/core/format/money_format.dart';
import 'package:rider_app/core/l10n/app_locales.dart';
import 'package:rider_app/core/l10n/l10n.dart';
import 'package:rider_app/design/map/app_map.dart';
import 'package:rider_app/features/booking/domain/entities/trip_draft.dart';
import 'package:rider_app/features/booking/presentation/choose_ride/choose_ride_screen.dart';

import '../../../helpers/pump_app.dart';
import '../fakes.dart';

final _draft = TripDraft(pickup: spotNamed('Gulan'), destination: spotNamed('Family Mall'));

Future<void> _open(WidgetTester tester, {FakeRides? rides, Locale? locale}) async {
  usePhoneScreen(tester);
  await pumpApp(
    tester,
    ChooseRideScreen(draft: _draft),
    locale: locale ?? AppLocales.arabic,
    inScaffold: false,
    overrides: bookingFakes(rides: rides),
  );
}

void main() {
  setUp(() => AppMap.usePlaceholder = true);
  tearDown(() => AppMap.usePlaceholder = false);

  final l10n = lookupAppLocalizations(AppLocales.arabic);

  testWidgets('both ride types with prices; choosing one names it on the button',
      (tester) async {
    await _open(tester);

    expect(find.text(l10n.vehicleEconomy), findsOneWidget);
    expect(find.text(formatMoney(l10n, 3750)), findsOneWidget);
    expect(find.text(l10n.chooseRideOrder(l10n.vehicleEconomy)), findsOneWidget);

    await tester.tap(find.text(l10n.vehicleComfort));
    await tester.pumpAndSettle();

    expect(find.text(l10n.chooseRideOrder(l10n.vehicleComfort)), findsOneWidget);
  });

  testWidgets('a surge and a ride type without captains are said in words', (tester) async {
    await _open(
      tester,
      rides: FakeRides(quotes: [
        quoteOf('economy', 3000, surging: true),
        quoteOf('comfort', 3750, driversAvailable: false),
      ]),
    );

    expect(find.text(l10n.chooseRideSurge), findsOneWidget);
    expect(find.textContaining(l10n.chooseRideNoCaptains), findsOneWidget);
  });

  testWidgets('a coupon from the sheet lowers the price; the wallet shows its balance',
      (tester) async {
    await _open(tester);

    await tester.tap(find.text(l10n.couponChip));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'bts26');
    await tester.tap(find.text(l10n.couponApply));
    await tester.pumpAndSettle();

    expect(find.text(l10n.couponApplied(FakeRides.goodCode)), findsOneWidget);
    expect(find.text(l10n.paymentWalletBalance(formatMoney(l10n, 12500))), findsOneWidget);

    await tester.tap(find.text(l10n.paymentWallet));
    // The sheet scrolls on a phone once the coupon's message shows.
    await tester.ensureVisible(find.text(l10n.actionConfirm));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.actionConfirm));
    await tester.pumpAndSettle();

    expect(find.text(l10n.paymentWallet), findsOneWidget);
    expect(find.text(l10n.chooseRideCouponApplied), findsNWidgets(2));
  });

  testWidgets('a refused request says what the rider can do', (tester) async {
    await _open(tester, rides: FakeRides(orderFailure: const PreconditionFailure()));

    await tester.tap(find.text(l10n.chooseRideOrder(l10n.vehicleEconomy)));
    await tester.pumpAndSettle();

    expect(find.text(l10n.chooseRideNotNow), findsOneWidget);
  });

  testWidgets('a pickup outside the service area cannot be ordered', (tester) async {
    await _open(tester, rides: FakeRides(quoteFailure: const InvalidInputFailure()));

    expect(find.text(l10n.chooseRideOutsideArea), findsOneWidget);
    expect(find.text(l10n.actionRetry), findsNothing);
  });

  for (final locale in AppLocales.all) {
    testWidgets('choosing a ride fits a phone: ${locale.languageCode}', (tester) async {
      await _open(tester, locale: locale, rides: FakeRides(quotes: [
        quoteOf('economy', 3000, beforeDiscount: 4250, surging: true),
        quoteOf('comfort', 3750, driversAvailable: false),
      ]));

      expect(tester.takeException(), isNull);
    });
  }
}
