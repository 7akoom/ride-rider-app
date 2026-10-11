import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/error/result.dart';
import 'package:rider_app/core/format/money_format.dart';
import 'package:rider_app/core/l10n/app_locales.dart';
import 'package:rider_app/core/l10n/l10n.dart';
import 'package:rider_app/features/wallet/domain/entities/statement.dart';
import 'package:rider_app/features/wallet/domain/entities/wallet_movement.dart';
import 'package:rider_app/features/wallet/domain/entities/wallet_overview.dart';
import 'package:rider_app/features/wallet/presentation/movements_screen.dart';
import 'package:rider_app/features/wallet/presentation/statement_screen.dart';
import 'package:rider_app/features/wallet/presentation/wallet_screen.dart';

import '../../../helpers/pump_app.dart';
import '../../booking/fakes.dart';

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
    inScaffold: false,
    settle: false,
    overrides: bookingFakes(wallet: wallet),
  );
  await _wait(tester);
}

void main() {
  final l10n = lookupAppLocalizations(AppLocales.arabic);

  testWidgets('the wallet shows its balance, what is owed and the latest movements', (tester) async {
    await _open(
      tester,
      const WalletScreen(),
      wallet: FakeWallet(overviewResult: const Ok(WalletOverview(balance: 12500, owed: 1000))),
    );

    expect(find.text(formatMoney(l10n, 12500)), findsOneWidget);
    expect(find.text(l10n.walletOwed(formatMoney(l10n, 1000))), findsOneWidget);
    expect(find.text(l10n.movementTopUp), findsOneWidget);
    expect(find.text(formatMoney(l10n, 10000, signed: true)), findsOneWidget);
    expect(find.text(formatMoney(l10n, -3000)), findsOneWidget);
  });

  testWidgets('the eye hides the balance and shows it again', (tester) async {
    await _open(tester, const WalletScreen());

    await tester.tap(find.byTooltip(l10n.walletHide));
    await _wait(tester);
    expect(find.text(formatMoney(l10n, 12500)), findsNothing);

    await tester.tap(find.byTooltip(l10n.walletShow));
    await _wait(tester);
    expect(find.text(formatMoney(l10n, 12500)), findsOneWidget);
  });

  testWidgets('the statement adds the period up', (tester) async {
    await _open(tester, const StatementScreen());

    expect(find.text(l10n.statementOpening), findsOneWidget);
    expect(find.text(formatMoney(l10n, 9500)), findsOneWidget);
    expect(find.text(l10n.movementVoucher), findsOneWidget);
    expect(find.textContaining(l10n.movementBalanceAfter(formatMoney(l10n, 12500))), findsOneWidget);
  });

  testWidgets('the history asks for the next page, and filters', (tester) async {
    final wallet = FakeWallet(pages: [
      StatementPage(
        movements: [for (var i = 0; i < 12; i++) movementOf(MovementKind.tripPayment, -1000, id: 'p$i')],
        opening: 0, closing: 0, totalIn: 0, totalOut: 12000, next: '1',
      ),
      StatementPage(movements: [movementOf(MovementKind.refund, 500, id: 'r')], opening: 0, closing: 0, totalIn: 500, totalOut: 0),
    ]);
    await _open(tester, const MovementsScreen(), wallet: wallet);

    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await _wait(tester);
    expect(wallet.asked.map((a) => a.$2), contains('1'));

    await tester.drag(find.byType(ListView), const Offset(0, 3000));
    await _wait(tester);
    await tester.tap(find.text(l10n.filterTips));
    await _wait(tester);
    expect(wallet.asked.last.$1, MovementFilter.tips);
  });

  for (final locale in AppLocales.all) {
    testWidgets('the wallet screens fit a phone: ${locale.languageCode}', (tester) async {
      await _open(tester, const WalletScreen(), locale: locale);
      expect(tester.takeException(), isNull);
      await _open(tester, const StatementScreen(), locale: locale);
      expect(tester.takeException(), isNull);
      await _open(tester, const MovementsScreen(), locale: locale);
      expect(tester.takeException(), isNull);
    });
  }
}
