import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/error/failure.dart';
import 'package:rider_app/core/error/result.dart';
import 'package:rider_app/core/format/money_format.dart';
import 'package:rider_app/core/l10n/app_locales.dart';
import 'package:rider_app/core/l10n/l10n.dart';
import 'package:rider_app/design/components/components.dart';
import 'package:rider_app/features/wallet/domain/entities/voucher_credit.dart';
import 'package:rider_app/features/wallet/domain/entities/wallet_overview.dart';
import 'package:rider_app/features/wallet/presentation/voucher_sheet.dart';
import 'package:rider_app/features/wallet/presentation/wallet_screen.dart';

import '../../../helpers/pump_app.dart';
import '../../booking/fakes.dart';

const _code = 'ABCD-EFGH-JKMN-PQRS';

Future<void> _wait(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(milliseconds: 600));
}

Future<void> _open(WidgetTester tester, Widget screen, {FakeWallet? wallet, Locale? locale}) async {
  usePhoneScreen(tester);
  await pumpApp(
    tester,
    screen,
    locale: locale ?? AppLocales.arabic,
    // A sheet alone needs the Material a screen gives it.
    inScaffold: screen is VoucherSheet,
    settle: false,
    overrides: bookingFakes(wallet: wallet),
  );
  await _wait(tester);
}

AppButton _redeemButton(WidgetTester tester, AppLocalizations l10n) =>
    tester.widget<AppButton>(find.widgetWithText(AppButton, l10n.voucherApply));

void main() {
  final l10n = lookupAppLocalizations(AppLocales.arabic);

  testWidgets('the wallet opens the voucher sheet, and a voucher adds to it', (tester) async {
    final wallet = FakeWallet(overviewResult: const Ok(WalletOverview(balance: 12500, owed: 1000)));
    await _open(tester, const WalletScreen(), wallet: wallet);

    await tester.tap(find.text(l10n.walletUseVoucher));
    await _wait(tester);
    expect(find.text(l10n.voucherTitle), findsOneWidget);
    expect(_redeemButton(tester, l10n).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'abcd efgh-jkmn pqrs');
    await tester.pump();
    expect(_redeemButton(tester, l10n).onPressed, isNotNull);

    await tester.tap(find.text(l10n.voucherApply));
    await _wait(tester);
    expect(wallet.redeemed, ['ABCDEFGHJKMNPQRS']);
    expect(find.text(l10n.voucherAdded(formatMoney(l10n, 10000))), findsOneWidget);
    expect(find.text(l10n.voucherBalance(formatMoney(l10n, 22500))), findsOneWidget);
    expect(find.text(l10n.voucherDuesFirst), findsOneWidget);

    await tester.tap(find.text(l10n.voucherDone));
    await _wait(tester);
    expect(find.text(l10n.voucherTitle), findsNothing);
  });

  testWidgets('a voucher this rider had redeemed says nothing more was added', (tester) async {
    await _open(
      tester,
      const VoucherSheet(owed: 1000),
      wallet: FakeWallet(
        voucherResult: const Ok(VoucherCredit(amount: 10000, balance: 10000, alreadyRedeemed: true)),
      ),
    );

    await tester.enterText(find.byType(TextField), _code);
    await tester.pump();
    await tester.tap(find.text(l10n.voucherApply));
    await _wait(tester);
    expect(find.text(l10n.voucherAlready), findsOneWidget);
    expect(find.text(l10n.voucherAlreadyBody(formatMoney(l10n, 10000))), findsOneWidget);
    expect(find.text(l10n.voucherAdded(formatMoney(l10n, 10000))), findsNothing);
    expect(find.text(l10n.voucherDuesFirst), findsNothing);
  });

  testWidgets('a character no code has is pointed out at once', (tester) async {
    await _open(tester, const VoucherSheet());

    await tester.enterText(find.byType(TextField), 'ABCD-0');
    await tester.pump();
    expect(find.text(l10n.voucherFormat), findsOneWidget);
  });

  final refusals = <Failure, String>{
    const NotFoundFailure(): l10n.voucherWrong,
    const PreconditionFailure(): l10n.voucherUnusable,
    const RateLimitedFailure(): l10n.voucherTooMany,
  };
  for (final MapEntry(key: failure, value: message) in refusals.entries) {
    testWidgets('a refused voucher says why: ${failure.runtimeType}', (tester) async {
      await _open(tester, const VoucherSheet(), wallet: FakeWallet(voucherResult: Err(failure)));

      await tester.enterText(find.byType(TextField), _code);
      await tester.pump();
      await tester.tap(find.text(l10n.voucherApply));
      await _wait(tester);
      expect(find.text(message), findsOneWidget);

      // Typing again clears it.
      await tester.enterText(find.byType(TextField), '${_code}T');
      await tester.pump();
      expect(find.text(message), findsNothing);
    });
  }

  for (final locale in AppLocales.all) {
    testWidgets('the voucher sheet fits a phone: ${locale.languageCode}', (tester) async {
      await _open(tester, const VoucherSheet(), locale: locale);
      expect(tester.takeException(), isNull);
      await tester.enterText(find.byType(TextField), _code);
      await tester.pump();
      await tester.tap(find.byType(AppButton));
      await _wait(tester);
      expect(tester.takeException(), isNull);
    });
  }
}
