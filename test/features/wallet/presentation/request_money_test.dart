import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/error/failure.dart';
import 'package:rider_app/core/format/money_format.dart';
import 'package:rider_app/core/l10n/app_locales.dart';
import 'package:rider_app/core/l10n/l10n.dart';
import 'package:rider_app/core/share/share_text.dart';
import 'package:rider_app/design/components/components.dart';
import 'package:rider_app/features/wallet/domain/entities/money_request.dart';
import 'package:rider_app/features/wallet/presentation/contact_picker.dart';
import 'package:rider_app/features/wallet/presentation/money_request_screen.dart';
import 'package:rider_app/features/wallet/presentation/money_requests_screen.dart';
import 'package:rider_app/features/wallet/presentation/pin_sheet.dart';
import 'package:rider_app/features/wallet/presentation/request_money_screen.dart';
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
  FakeMoneyRequests? requests,
  FakeWalletPin? pins,
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
      ...bookingFakes(requests: requests, walletPin: pins),
      pickContactNumbersProvider.overrideWithValue(() async => null),
      shareTextProvider.overrideWithValue((text) async => shared?.add(text)),
    ],
  );
  await _wait(tester);
}

/// Types [digits] on the PIN sheet's pad.
Future<void> _typePin(WidgetTester tester, String digits) async {
  for (final digit in digits.split('')) {
    await tester.tap(find.descendant(of: find.byType(PinSheet), matching: find.text(digit)));
    await tester.pump();
  }
  await _wait(tester);
}

/// 5,000 picked and "continue": the choice of whom to ask.
Future<void> _toWho(WidgetTester tester, AppLocalizations l10n) async {
  await tester.tap(find.text(formatAmount(5000)));
  await _wait(tester);
  await tester.tap(find.text(l10n.sendContinue));
  await _wait(tester);
}

AppButton _button(WidgetTester tester, String label) => tester.widget<AppButton>(find.widgetWithText(AppButton, label));

void main() {
  final l10n = lookupAppLocalizations(AppLocales.arabic);
  final amount = formatMoney(l10n, 5000);

  testWidgets('a rider is asked by phone, after seeing whose number it is', (tester) async {
    final requests = FakeMoneyRequests();
    await _open(tester, const RequestMoneyScreen(), requests: requests);
    expect(_button(tester, l10n.sendContinue).onPressed, isNull);

    await _toWho(tester, l10n);
    expect(find.text(l10n.requestWhoTitle), findsOneWidget);
    expect(_button(tester, l10n.requestCreate(amount)).onPressed, isNull);

    await tester.enterText(find.byType(EditableText), '0750 123 4567');
    await _wait(tester);
    expect(find.text('Haidar K.'), findsOneWidget);

    await tester.tap(find.text(l10n.requestCreate(amount)));
    await _wait(tester);
    expect(requests.created.single.phone, '+9647501234567');
    expect(requests.created.single.amount, 5000);
    expect(find.text(l10n.requestSentTitle('Haidar K.', amount)), findsOneWidget);
  });

  testWidgets('a number that is no rider cannot be asked', (tester) async {
    await _open(tester, const RequestMoneyScreen());
    await _toWho(tester, l10n);

    await tester.enterText(find.byType(EditableText), '07701111111');
    await _wait(tester);
    expect(find.text(l10n.requestNotRegistered), findsOneWidget);
    expect(_button(tester, l10n.requestCreate(amount)).onPressed, isNull);
  });

  testWidgets('an open request shows its QR code and code, and shares the code', (tester) async {
    final requests = FakeMoneyRequests();
    final shared = <String>[];
    await _open(tester, const RequestMoneyScreen(), requests: requests, shared: shared);
    await _toWho(tester, l10n);

    await tester.tap(find.text(l10n.requestKindOpen));
    await _wait(tester);
    expect(find.text(l10n.requestOpenBody), findsOneWidget);

    await tester.tap(find.text(l10n.requestCreateOpen(amount)));
    await _wait(tester);
    expect(requests.created.single.phone, isNull);
    expect(find.text(l10n.requestOpenTitle(amount)), findsOneWidget);
    expect(find.textContaining('NEWRQ-2ABCD'), findsOneWidget);

    await tester.scrollUntilVisible(find.text(l10n.requestShare), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text(l10n.requestShare));
    await tester.pump();
    expect(shared.single, contains('NEWRQ-2ABCD'));
  });

  testWidgets('the wallet shows what is asked of the rider, who pays it with the PIN', (tester) async {
    final requests = FakeMoneyRequests(requests: [requestOf()]);
    await _open(tester, const WalletScreen(), requests: requests);
    expect(find.text(l10n.walletRequest), findsOneWidget);
    expect(find.text(l10n.walletIncomingTitle), findsOneWidget);

    await tester.tap(find.text(l10n.requestFrom('Haidar K.')));
    await _wait(tester);
    expect(find.text(l10n.sendAvailable(formatMoney(l10n, 12500))), findsOneWidget);

    await tester.tap(find.text(l10n.requestPay(amount)));
    await _wait(tester);
    expect(find.text(l10n.requestPinDetail(amount, 'Haidar K.')), findsOneWidget);

    await _typePin(tester, '2580');
    expect(requests.paid.single, ('K7XMQ2PQRX', '2580'));
    expect(find.text(l10n.requestPaidTitle(amount, 'Haidar K.')), findsOneWidget);
    expect(find.text(formatMoney(l10n, 7500)), findsOneWidget);
  });

  testWidgets('a wrong PIN keeps the sheet open with the tries left', (tester) async {
    final requests = FakeMoneyRequests(requests: [requestOf()]);
    await _open(tester, const MoneyRequestScreen(code: 'K7XMQ2PQRX'), requests: requests);

    await tester.tap(find.text(l10n.requestPay(amount)));
    await _wait(tester);
    await _typePin(tester, '1111');
    expect(find.text(l10n.pinWrongCurrent(5)), findsOneWidget);
    expect(find.text(l10n.pinSheetTitle), findsOneWidget);

    await _typePin(tester, '2580');
    expect(find.text(l10n.requestPaidTitle(amount, 'Haidar K.')), findsOneWidget);
  });

  testWidgets('more than the balance cannot be paid', (tester) async {
    final requests = FakeMoneyRequests(requests: [requestOf(amount: 20000)]);
    await _open(tester, const MoneyRequestScreen(code: 'K7XMQ2PQRX'), requests: requests);

    expect(find.text(l10n.sendOverBalance), findsOneWidget);
    expect(_button(tester, l10n.requestPay(formatMoney(l10n, 20000))).onPressed, isNull);
  });

  testWidgets('paid by someone else meanwhile: the request says it is paid', (tester) async {
    final requests = FakeMoneyRequests(
      requests: [requestOf(open: true, role: MoneyRequestRole.viewer)],
      payFailure: const PreconditionFailure(),
    );
    await _open(tester, const MoneyRequestScreen(code: 'K7XMQ2PQRX'), requests: requests);

    await tester.tap(find.text(l10n.requestPay(amount)));
    await _wait(tester);
    requests.requests[0] = requests.requests[0].copyWith(status: MoneyRequestStatus.paid);
    await _typePin(tester, '2580');
    expect(find.text(l10n.pinSheetTitle), findsNothing);
    expect(find.text(l10n.requestStatusPaid), findsOneWidget);
    expect(find.text(l10n.requestPay(amount)), findsNothing);
  });

  testWidgets('the rider asked declines, after confirming', (tester) async {
    final requests = FakeMoneyRequests(requests: [requestOf()]);
    await _open(tester, const MoneyRequestScreen(code: 'K7XMQ2PQRX'), requests: requests);

    await tester.tap(find.text(l10n.requestDecline));
    await _wait(tester);
    expect(find.text(l10n.requestDeclineTitle), findsOneWidget);

    await tester.tap(find.widgetWithText(AppButton, l10n.requestDecline).last);
    await _wait(tester);
    expect(requests.declined, ['K7XMQ2PQRX']);
    expect(find.text(l10n.requestStatusDeclined), findsOneWidget);
    expect(find.text(l10n.requestPay(amount)), findsNothing);
  });

  testWidgets('an open request of the rider\'s shows its QR code and can be cancelled', (tester) async {
    final requests = FakeMoneyRequests(requests: [
      requestOf(role: MoneyRequestRole.requester, open: true, requesterName: 'Me', requesterPhone: '+9647500000000'),
    ]);
    await _open(tester, const MoneyRequestScreen(code: 'K7XMQ2PQRX'), requests: requests);
    expect(find.text(l10n.requestShare), findsOneWidget);
    expect(find.text(l10n.requestDecline), findsNothing);

    await tester.tap(find.text(l10n.requestCancel));
    await _wait(tester);
    await tester.tap(find.widgetWithText(AppButton, l10n.requestCancel).last);
    await _wait(tester);
    expect(requests.cancelled, ['K7XMQ2PQRX']);
    expect(find.text(l10n.requestStatusCancelled), findsOneWidget);
  });

  testWidgets('a code typed in lower case, with a dash, opens the request', (tester) async {
    final requests = FakeMoneyRequests(requests: [requestOf(open: true, role: MoneyRequestRole.viewer)]);
    await _open(tester, const MoneyRequestsScreen(), requests: requests);

    await tester.tap(find.text(l10n.requestPayWithCode));
    await _wait(tester);
    await tester.enterText(find.byType(EditableText), 'k7xm');
    // The button is on once something is typed.
    await tester.pump();
    await tester.tap(find.text(l10n.payCodeOpen));
    await _wait(tester);
    expect(find.text(l10n.payCodeInvalid), findsOneWidget);

    await tester.enterText(find.byType(EditableText), 'k7xmq-2pqrx');
    await tester.pump();
    await tester.tap(find.text(l10n.payCodeOpen));
    await _wait(tester);
    expect(find.text(l10n.requestDetailTitle), findsOneWidget);
    expect(find.text(l10n.requestPay(amount)), findsOneWidget);
  });

  testWidgets('a code nobody has', (tester) async {
    await _open(tester, const MoneyRequestScreen(code: 'ABCDEABCDE'));

    expect(find.text(l10n.requestNotFound), findsOneWidget);
  });

  testWidgets('my requests list both sides', (tester) async {
    final requests = FakeMoneyRequests(requests: [
      requestOf(),
      requestOf(code: 'ABCDE23456', role: MoneyRequestRole.requester, payerName: 'Sara A.', status: MoneyRequestStatus.paid),
    ]);
    await _open(tester, const MoneyRequestsScreen(), requests: requests);
    expect(find.text(l10n.requestFrom('Haidar K.')), findsOneWidget);
    expect(find.text(l10n.requestTo('Sara A.')), findsNothing);

    await tester.tap(find.text(l10n.requestsOutgoing));
    await _wait(tester);
    expect(find.text(l10n.requestTo('Sara A.')), findsOneWidget);
    expect(find.text(l10n.requestStatusPaid), findsOneWidget);
  });

  for (final locale in AppLocales.all) {
    testWidgets('the request screens fit a phone: ${locale.languageCode}', (tester) async {
      final local = lookupAppLocalizations(locale);
      final requests = FakeMoneyRequests(requests: [requestOf()]);
      await _open(tester, const RequestMoneyScreen(), requests: requests, locale: locale);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text(formatAmount(5000)));
      await _wait(tester);
      await tester.tap(find.text(local.sendContinue));
      await _wait(tester);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text(local.requestKindOpen));
      await _wait(tester);
      await tester.tap(find.text(local.requestCreateOpen(formatMoney(local, 5000))));
      await _wait(tester);
      expect(tester.takeException(), isNull);

      await _open(tester, const MoneyRequestScreen(code: 'K7XMQ2PQRX'), requests: requests, locale: locale);
      expect(tester.takeException(), isNull);

      await _open(tester, const WalletScreen(), requests: requests, locale: locale);
      expect(tester.takeException(), isNull);
    });
  }
}
