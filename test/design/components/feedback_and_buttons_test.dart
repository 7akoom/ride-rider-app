import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/error/failure.dart';
import 'package:rider_app/core/format/money_format.dart';
import 'package:rider_app/core/l10n/app_locales.dart';
import 'package:rider_app/core/l10n/l10n.dart';
import 'package:rider_app/design/components/components.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('a loading button shows the dots and ignores taps', (tester) async {
    var taps = 0;

    await pumpApp(
      tester,
      AppButton(label: 'x', onPressed: () => taps++, loading: true),
      settle: false,
    );

    expect(find.byType(LoadingDots), findsOneWidget);
    expect(find.text('x'), findsNothing);
    await tester.tap(find.byType(AppButton), warnIfMissed: false);
    expect(taps, 0);
  });

  testWidgets('the failure view shows the translated message and retries', (tester) async {
    var retries = 0;
    final l10n = lookupAppLocalizations(AppLocales.kurdish);

    await pumpApp(
      tester,
      FailureView(failure: const NetworkFailure(), onRetry: () => retries++),
      locale: AppLocales.kurdish,
    );

    expect(find.text(l10n.errorNoConnection), findsOneWidget);
    await tester.tap(find.text(l10n.actionRetry));
    expect(retries, 1);
  });

  testWidgets('money is shown with the language currency', (tester) async {
    final l10n = lookupAppLocalizations(AppLocales.arabic);

    await pumpApp(tester, const MoneyText(3000));

    expect(find.text(formatMoney(l10n, 3000)), findsOneWidget);
  });

  testWidgets('the back button appears on pushed screens with its label', (tester) async {
    final l10n = lookupAppLocalizations(AppLocales.arabic);

    await pumpApp(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => const Scaffold(appBar: AppTopBar(), body: SizedBox()),
          )),
          child: const SizedBox.square(dimension: 40),
        ),
      ),
    );

    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();

    expect(find.byTooltip(l10n.actionBack), findsOneWidget);
    await tester.tap(find.byTooltip(l10n.actionBack));
    await tester.pumpAndSettle();
    expect(find.byType(AppTopBar), findsNothing);
  });
}
