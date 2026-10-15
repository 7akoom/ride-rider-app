import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/error/result.dart';
import 'package:rider_app/core/format/money_format.dart';
import 'package:rider_app/core/l10n/app_locales.dart';
import 'package:rider_app/core/l10n/l10n.dart';
import 'package:rider_app/design/components/components.dart';
import 'package:rider_app/features/wallet/domain/entities/top_up.dart';
import 'package:rider_app/features/wallet/presentation/top_up_controller.dart';
import 'package:rider_app/features/wallet/presentation/top_up_screen.dart';
import 'package:rider_app/features/wallet/presentation/wallet_screen.dart';

import '../../../helpers/pump_app.dart';
import '../../booking/fakes.dart';

const _options = TopUpOptions(min: 1000, max: 1000000, providers: [TopUpOptions.zainCash]);

Future<void> _wait(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(milliseconds: 600));
}

/// Opens [screen]; the payment pages it opens land in [opened].
Future<void> _open(
  WidgetTester tester,
  Widget screen, {
  FakeWallet? wallet,
  List<Uri>? opened,
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
      ...bookingFakes(wallet: wallet),
      topUpPageOpenerProvider.overrideWithValue((context, page) async {
        opened?.add(page);

        return true;
      }),
    ],
  );
  await _wait(tester);
}

AppButton _next(WidgetTester tester, AppLocalizations l10n) =>
    tester.widget<AppButton>(find.widgetWithText(AppButton, l10n.topUpNext));

/// Types [keys] on the pad.
Future<void> _type(WidgetTester tester, List<String> keys) async {
  for (final key in keys) {
    await tester.tap(find.text(key));
    await tester.pump();
  }
}

/// 5,000 picked, reviewed, paid.
Future<void> _pay(WidgetTester tester, AppLocalizations l10n) async {
  await tester.tap(find.text(formatAmount(5000)));
  await tester.pump();
  await tester.tap(find.text(l10n.topUpNext));
  await _wait(tester);
  await tester.tap(find.text(l10n.topUpPay(formatMoney(l10n, 5000))));
  await _wait(tester);
}

/// The controller's checks: [count] periods of TopUpController.checkEvery.
Future<void> _checks(WidgetTester tester, int count) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(TopUpController.checkEvery);
  }
  await tester.pump();
}

void main() {
  final l10n = lookupAppLocalizations(AppLocales.arabic);

  testWidgets('the wallet offers a top-up where ZainCash is set up', (tester) async {
    await _open(tester, const WalletScreen());
    expect(find.text(l10n.walletTopUp), findsOneWidget);
  });

  testWidgets('without ZainCash the wallet offers vouchers only', (tester) async {
    await _open(
      tester,
      const WalletScreen(),
      wallet: FakeWallet(topUpOptionsResult: const Ok(TopUpOptions(min: 1000, max: 1000000))),
    );
    expect(find.text(l10n.walletTopUp), findsNothing);
    expect(find.text(l10n.walletUseVoucher), findsOneWidget);
  });

  testWidgets('a ready amount is one tap; one outside the limits cannot be picked', (tester) async {
    await _open(tester, const TopUpScreen(options: TopUpOptions(min: 1000, max: 20000, providers: [TopUpOptions.zainCash])));
    expect(_next(tester, l10n).onPressed, isNull);

    await tester.tap(find.text(formatAmount(25000)));
    await tester.pump();
    expect(_next(tester, l10n).onPressed, isNull);

    await tester.tap(find.text(formatAmount(10000)));
    await tester.pump();
    expect(find.text(formatMoney(l10n, 10000)), findsOneWidget);
    expect(_next(tester, l10n).onPressed, isNotNull);
  });

  testWidgets('another amount is typed on the pad in a sheet, within the limits', (tester) async {
    await _open(tester, const TopUpScreen(options: _options));

    await tester.tap(find.text(l10n.amountOther));
    await _wait(tester);
    AppButton done() => tester.widget<AppButton>(find.widgetWithText(AppButton, l10n.amountOtherDone));

    await _type(tester, ['5', '0', '0']);
    expect(find.text(l10n.topUpTooSmall(formatMoney(l10n, 1000))), findsOneWidget);
    expect(done().onPressed, isNull);

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byIcon(Icons.backspace_outlined));
      await tester.pump();
    }
    await _type(tester, ['7', '000']);
    expect(done().onPressed, isNotNull);

    await tester.tap(find.text(l10n.amountOtherDone));
    await _wait(tester);
    expect(find.text(formatMoney(l10n, 7000)), findsOneWidget);
    // The typed amount shows on the "another amount" chip, picked.
    expect(find.text(formatAmount(7000)), findsOneWidget);
    expect(find.text(l10n.amountOther), findsNothing);
    expect(_next(tester, l10n).onPressed, isNotNull);
  });

  testWidgets('a paid top-up: the page opens, the payment is followed, the money arrives', (tester) async {
    final wallet = FakeWallet(statuses: [const Ok(TopUpStatus.pending), const Ok(TopUpStatus.succeeded)]);
    final opened = <Uri>[];
    await _open(tester, const TopUpScreen(options: _options), wallet: wallet, opened: opened);

    await _pay(tester, l10n);
    expect(wallet.startedTopUps, [(5000, 'ar')]);
    expect(opened, [Uri.parse('https://pay.example/topup-1')]);
    // The page closed (here at once): the server is asked straight away.
    expect(wallet.topUpChecks, 1);
    expect(find.text(l10n.topUpWaitingTitle), findsOneWidget);

    await _checks(tester, 1);
    expect(find.text(l10n.topUpDoneTitle(formatMoney(l10n, 5000))), findsOneWidget);
    expect(wallet.topUpChecks, 2);

    // Done: nobody asks again.
    await _checks(tester, 3);
    expect(wallet.topUpChecks, 2);
  });

  testWidgets('the payment page can be opened again while it is followed', (tester) async {
    final opened = <Uri>[];
    await _open(tester, const TopUpScreen(options: _options), opened: opened);

    await _pay(tester, l10n);
    await tester.tap(find.text(l10n.topUpReopen));
    await _wait(tester);
    expect(opened.length, 2);
  });

  testWidgets('a failed top-up says so, and the same amount can be paid again', (tester) async {
    final wallet = FakeWallet(statuses: [const Ok(TopUpStatus.failed)]);
    await _open(tester, const TopUpScreen(options: _options), wallet: wallet);

    await _pay(tester, l10n);
    await _checks(tester, 1);
    expect(find.text(l10n.topUpFailedTitle), findsOneWidget);

    await tester.tap(find.text(l10n.topUpTryAgain));
    await _wait(tester);
    expect(find.text(formatMoney(l10n, 5000)), findsOneWidget);
    expect(_next(tester, l10n).onPressed, isNotNull);
  });

  testWidgets('a confirmation that is late says the money still comes', (tester) async {
    await _open(tester, const TopUpScreen(options: _options));

    await _pay(tester, l10n);
    await _checks(tester, TopUpController.slowAfterChecks);
    expect(find.text(l10n.topUpSlowTitle), findsOneWidget);
    expect(find.text(l10n.topUpSlowBody(formatMoney(l10n, 5000))), findsOneWidget);
  });

  for (final locale in AppLocales.all) {
    testWidgets('the top-up screens fit a phone: ${locale.languageCode}', (tester) async {
      final local = lookupAppLocalizations(locale);
      await _open(tester, const TopUpScreen(options: _options), locale: locale);
      expect(tester.takeException(), isNull);

      await _pay(tester, local);
      expect(tester.takeException(), isNull);

      await _checks(tester, TopUpController.slowAfterChecks);
      expect(tester.takeException(), isNull);
    });
  }
}
