import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/error/failure.dart';
import 'package:rider_app/core/error/result.dart';
import 'package:rider_app/core/format/money_format.dart';
import 'package:rider_app/core/l10n/app_locales.dart';
import 'package:rider_app/core/l10n/l10n.dart';
import 'package:rider_app/core/phone/phone_number.dart';
import 'package:rider_app/core/share/share_text.dart';
import 'package:rider_app/design/components/components.dart';
import 'package:rider_app/features/wallet/domain/entities/wallet_overview.dart';
import 'package:rider_app/features/wallet/presentation/contact_picker.dart';
import 'package:rider_app/features/wallet/presentation/pin_sheet.dart';
import 'package:rider_app/features/wallet/presentation/send_money_screen.dart';
import 'package:rider_app/features/wallet/presentation/wallet_screen.dart';

import '../../../helpers/pump_app.dart';
import '../../booking/fakes.dart';

Future<void> _wait(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(milliseconds: 600));
}

Future<void> _open(
  WidgetTester tester,
  Widget screen, {
  FakeTransfers? transfers,
  FakeWalletPin? pins,
  FakeWallet? wallet,
  List<String>? contact,
  List<String>? shared,
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
      ...bookingFakes(transfers: transfers, walletPin: pins, wallet: wallet),
      pickContactNumbersProvider.overrideWithValue(() async => contact),
      shareTextProvider.overrideWithValue((text) async => shared?.add(text)),
    ],
  );
  await _wait(tester);
}

/// Types [digits] on the PIN sheet's pad (the amount's pad is under it).
Future<void> _typePin(WidgetTester tester, String digits) async {
  for (final digit in digits.split('')) {
    await tester.tap(find.descendant(of: find.byType(PinSheet), matching: find.text(digit)));
    await tester.pump();
  }
  await _wait(tester);
}

/// Types [keys] on the another-amount sheet's pad.
Future<void> _typeAmount(WidgetTester tester, List<String> keys) async {
  for (final key in keys) {
    await tester.tap(find.text(key));
    await tester.pump();
  }
  await _wait(tester);
}

/// Taps a ready amount.
Future<void> _pick(WidgetTester tester, int amount) async {
  await tester.tap(find.text(formatAmount(amount)));
  await _wait(tester);
}

/// A registered rider's phone, then on to the amount.
Future<void> _toAmount(WidgetTester tester, AppLocalizations l10n) async {
  await _phone(tester, '07501234567');
  await tester.tap(find.text(l10n.sendContinue));
  await _wait(tester);
}

/// [amount] picked, reviewed, and "send" tapped: the PIN sheet is open.
Future<void> _toPin(WidgetTester tester, AppLocalizations l10n, int amount) async {
  await _toAmount(tester, l10n);
  await _pick(tester, amount);
  await tester.tap(find.text(l10n.sendContinue));
  await _wait(tester);
  await tester.tap(find.text(l10n.sendNow(formatMoney(l10n, amount))));
  await _wait(tester);
}

Future<void> _phone(WidgetTester tester, String typed) async {
  await tester.enterText(find.byType(EditableText).first, typed);
  await _wait(tester);
}

AppButton _continue(WidgetTester tester, AppLocalizations l10n) =>
    tester.widget<AppButton>(find.widgetWithText(AppButton, l10n.sendContinue));

void main() {
  final l10n = lookupAppLocalizations(AppLocales.arabic);

  testWidgets('the wallet opens sending money', (tester) async {
    await _open(tester, const WalletScreen());

    await tester.tap(find.text(l10n.walletSend));
    await _wait(tester);
    expect(find.text(l10n.sendTitle), findsOneWidget);
  });

  testWidgets('money goes to a registered rider after a review, confirmed with the PIN', (tester) async {
    final transfers = FakeTransfers();
    final shared = <String>[];
    await _open(tester, const SendMoneyScreen(), transfers: transfers, shared: shared);
    expect(_continue(tester, l10n).onPressed, isNull);

    await _phone(tester, '0750 123 4567');
    expect(transfers.lookedUp, ['+9647501234567']);
    expect(find.text('Haidar K.'), findsOneWidget);

    await tester.tap(find.text(l10n.sendContinue));
    await _wait(tester);
    expect(find.text(l10n.sendAvailable(formatMoney(l10n, 12500))), findsOneWidget);
    expect(_continue(tester, l10n).onPressed, isNull);
    // No number pad until "another amount".
    expect(find.byType(NumericKeypad), findsNothing);

    await _pick(tester, 5000);
    expect(find.text(formatMoney(l10n, 5000)), findsOneWidget);
    await tester.enterText(find.byType(EditableText), 'dinner');
    await tester.pump();

    await tester.tap(find.text(l10n.sendContinue));
    await _wait(tester);
    // The review: nothing is sent before "send" and the PIN.
    expect(find.text(l10n.sendReviewTitle), findsOneWidget);
    expect(find.text(formatMoney(l10n, 7500)), findsOneWidget);
    expect(find.text('dinner'), findsOneWidget);
    expect(transfers.sent, isEmpty);

    await tester.tap(find.text(l10n.sendNow(formatMoney(l10n, 5000))));
    await _wait(tester);
    expect(find.text(l10n.pinSheetTitle), findsOneWidget);
    expect(find.text(l10n.sendPinDetail(formatMoney(l10n, 5000), 'Haidar K.')), findsOneWidget);
    expect(transfers.sent, isEmpty);

    await _typePin(tester, '2580');
    expect(transfers.sent.single.phone, '+9647501234567');
    expect(transfers.sent.single.amount, 5000);
    expect(transfers.sent.single.note, 'dinner');
    expect(transfers.sent.single.pin, '2580');
    expect(find.text(l10n.sendDoneTitle(formatMoney(l10n, 5000), 'Haidar K.')), findsOneWidget);
    expect(find.text(formatMoney(l10n, 7500)), findsOneWidget);

    await tester.tap(find.text(l10n.sendShare));
    await tester.pump();
    expect(shared.single, contains('Haidar K.'));
    // The receipt may go to someone else: the recipient's phone is not in it.
    expect(shared.single, isNot(contains('750')));
  });

  testWidgets('back from the review keeps the amount and the note', (tester) async {
    await _open(tester, const SendMoneyScreen());
    await _toAmount(tester, l10n);
    await _pick(tester, 3000);
    await tester.enterText(find.byType(EditableText), 'lunch');
    await tester.tap(find.text(l10n.sendContinue));
    await _wait(tester);

    await tester.tap(find.text(l10n.sendEditAmount));
    await _wait(tester);
    expect(find.text(formatMoney(l10n, 3000)), findsOneWidget);
    expect(find.text('lunch'), findsOneWidget);
  });

  testWidgets('a number that is no rider, or the rider\'s own, cannot go on', (tester) async {
    final transfers = FakeTransfers(self: '+9647709999999');
    await _open(tester, const SendMoneyScreen(), transfers: transfers);

    await _phone(tester, '07701111111');
    expect(find.text(l10n.sendNotRegistered), findsOneWidget);
    expect(_continue(tester, l10n).onPressed, isNull);

    await _phone(tester, '07709999999');
    expect(find.text(l10n.sendSelf), findsOneWidget);
    expect(_continue(tester, l10n).onPressed, isNull);

    transfers.lookupFailure = const RateLimitedFailure();
    await _phone(tester, '07702222222');
    expect(find.text(l10n.sendLookupTooMany), findsOneWidget);
  });

  testWidgets('a contact\'s number is looked up; recent recipients are one tap', (tester) async {
    final transfers = FakeTransfers(recent: [PhoneNumber.tryParse('07501234567')!]);
    await _open(tester, const SendMoneyScreen(), transfers: transfers, contact: ['+44 20 7946 0000', '0750 123 4567']);

    await tester.tap(find.text(l10n.sendPickContact));
    await _wait(tester);
    expect(transfers.lookedUp, ['+9647501234567']);
    expect(find.text('Haidar K.'), findsOneWidget);

    await _phone(tester, '');
    await tester.tap(find.textContaining('750 123 4567').last);
    await _wait(tester);
    expect(transfers.lookedUp, ['+9647501234567', '+9647501234567']);
  });

  testWidgets('more than the balance or the limits is caught before the PIN', (tester) async {
    await _open(
      tester,
      const SendMoneyScreen(),
      wallet: FakeWallet(overviewResult: const Ok(WalletOverview(balance: 3000))),
    );
    await _toAmount(tester, l10n);

    // 5,000 is more than the wallet holds: it cannot be picked.
    await _pick(tester, 5000);
    expect(find.text(formatMoney(l10n, 5000)), findsNothing);
    expect(_continue(tester, l10n).onPressed, isNull);

    await tester.tap(find.text(l10n.amountOther));
    await _wait(tester);
    AppButton done() => tester.widget<AppButton>(find.widgetWithText(AppButton, l10n.amountOtherDone));

    await _typeAmount(tester, ['4', '000']);
    expect(find.text(l10n.sendOverBalance), findsOneWidget);
    expect(done().onPressed, isNull);

    for (var i = 0; i < 4; i++) {
      await tester.tap(find.byIcon(Icons.backspace_outlined));
      await tester.pump();
    }
    await _typeAmount(tester, ['1', '0', '0']);
    expect(find.text(l10n.sendTooSmall(formatMoney(l10n, 250))), findsOneWidget);
    expect(done().onPressed, isNull);

    await _typeAmount(tester, ['0']);
    await tester.tap(find.text(l10n.amountOtherDone));
    await _wait(tester);
    expect(find.text(formatMoney(l10n, 1000)), findsOneWidget);
    expect(_continue(tester, l10n).onPressed, isNotNull);
  });

  testWidgets('a wrong PIN keeps the sheet open with the tries left', (tester) async {
    final transfers = FakeTransfers(sendResults: [const Err(ForbiddenFailure())]);
    final pins = FakeWalletPin(pin: '2580', attemptsLeft: 4);
    await _open(tester, const SendMoneyScreen(), transfers: transfers, pins: pins);
    await _toPin(tester, l10n, 1000);

    await _typePin(tester, '1111');
    expect(find.text(l10n.pinWrongCurrent(4)), findsOneWidget);
    expect(find.text(l10n.pinSheetTitle), findsOneWidget);

    transfers.sendResults = [];
    await _typePin(tester, '2580');
    expect(find.text(l10n.sendDoneTitle(formatMoney(l10n, 1000), 'Haidar K.')), findsOneWidget);
    // The same transfer each time: one key.
    expect(transfers.sent.map((s) => s.key).toSet().length, 1);
  });

  testWidgets('the balance went down meanwhile: back at the amount, which says so', (tester) async {
    final wallet = FakeWallet();
    final transfers = FakeTransfers(sendResults: [const Err(PreconditionFailure())]);
    await _open(tester, const SendMoneyScreen(), transfers: transfers, wallet: wallet);
    await _toPin(tester, l10n, 5000);

    wallet.overviewResult = const Ok(WalletOverview(balance: 2000));
    await _typePin(tester, '2580');
    expect(find.text(l10n.pinSheetTitle), findsNothing);
    expect(find.text(l10n.sendOverBalance), findsOneWidget);
    expect(find.text(l10n.sendReviewTitle), findsNothing);
  });

  testWidgets('without a PIN the rider creates one first', (tester) async {
    await _open(tester, const SendMoneyScreen(), pins: FakeWalletPin());
    await _toPin(tester, l10n, 1000);

    expect(find.text(l10n.pinCreateTitle), findsOneWidget);
  });

  for (final locale in AppLocales.all) {
    testWidgets('the send screens fit a phone: ${locale.languageCode}', (tester) async {
      final local = lookupAppLocalizations(locale);
      await _open(tester, const SendMoneyScreen(), locale: locale, transfers: FakeTransfers(recent: [
        PhoneNumber.tryParse('07501234567')!,
        PhoneNumber.tryParse('07701111111')!,
      ]));
      await _phone(tester, '07501234567');
      expect(tester.takeException(), isNull);

      await tester.tap(find.text(local.sendContinue));
      await _wait(tester);
      await _pick(tester, 5000);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text(local.amountOther));
      await _wait(tester);
      await _typeAmount(tester, ['7', '000']);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text(local.amountOtherDone));
      await _wait(tester);

      await tester.tap(find.text(local.sendContinue));
      await _wait(tester);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text(local.sendNow(formatMoney(local, 7000))));
      await _wait(tester);
      await _typePin(tester, '2580');
      expect(find.text(local.sendDoneTitle(formatMoney(local, 7000), 'Haidar K.')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
