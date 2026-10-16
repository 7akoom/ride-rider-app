import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/error/failure.dart';
import 'package:rider_app/core/error/result.dart';
import 'package:rider_app/core/format/money_format.dart';
import 'package:rider_app/core/l10n/app_locales.dart';
import 'package:rider_app/core/l10n/l10n.dart';
import 'package:rider_app/features/wallet/domain/entities/biometric.dart';
import 'package:rider_app/features/wallet/presentation/pin_sheet.dart';
import 'package:rider_app/features/wallet/presentation/send_money_screen.dart';
import 'package:rider_app/features/wallet/presentation/wallet_pin_controller.dart';
import 'package:rider_app/features/wallet/presentation/wallet_pin_screen.dart';
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
  required FakeBiometricPin biometric,
  FakeWalletPin? pins,
  FakeTransfers? transfers,
}) async {
  usePhoneScreen(tester);
  await pumpApp(
    tester,
    screen,
    locale: AppLocales.arabic,
    inScaffold: false,
    settle: false,
    overrides: bookingFakes(
      walletPin: pins ?? FakeWalletPin(pin: '2580'),
      transfers: transfers,
      biometric: biometric,
    ),
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

/// Types [digits] on the PIN screen's pad.
Future<void> _type(WidgetTester tester, String digits) async {
  for (final digit in digits.split('')) {
    await tester.tap(find.text(digit));
    await tester.pump();
  }
  await _wait(tester);
}

/// 5,000 to Haidar K., reviewed, and "send" tapped.
Future<void> _toPin(WidgetTester tester, AppLocalizations l10n) async {
  await tester.enterText(find.byType(EditableText).first, '07501234567');
  await _wait(tester);
  await tester.tap(find.text(l10n.sendContinue));
  await _wait(tester);
  await tester.tap(find.text(formatAmount(5000)));
  await _wait(tester);
  await tester.tap(find.text(l10n.sendContinue));
  await _wait(tester);
  await tester.tap(find.text(l10n.sendNow(formatMoney(l10n, 5000))));
  await _wait(tester);
}

Future<void> _toRow(WidgetTester tester, AppLocalizations l10n) =>
    tester.scrollUntilVisible(find.text(l10n.walletBiometricFingerprint), 300, scrollable: find.byType(Scrollable).first);

void main() {
  final l10n = lookupAppLocalizations(AppLocales.arabic);

  testWidgets('a phone without a fingerprint, or no PIN yet: no row', (tester) async {
    await _open(tester, const WalletScreen(), biometric: FakeBiometricPin());
    await tester.scrollUntilVisible(find.text(l10n.walletPinRow), 300, scrollable: find.byType(Scrollable).first);
    expect(find.text(l10n.walletBiometricFingerprint), findsNothing);
  });

  testWidgets('turning it on takes the PIN once and the fingerprint, then keeps the PIN', (tester) async {
    final biometric = FakeBiometricPin(kind: BiometricKind.fingerprint);
    final pins = FakeWalletPin(pin: '2580');
    await _open(tester, const WalletScreen(), biometric: biometric, pins: pins);
    await _toRow(tester, l10n);

    await tester.tap(find.text(l10n.walletBiometricFingerprint));
    await _wait(tester);
    expect(find.text(l10n.biometricEnableDetail), findsOneWidget);
    // Turning it on: no fingerprint button yet, only the pad.
    expect(find.text(l10n.pinUseFingerprint), findsNothing);

    await _typePin(tester, '9999');
    expect(find.text(l10n.pinWrongCurrent(4)), findsOneWidget);
    expect(biometric.pin, isNull);

    await _typePin(tester, '2580');
    expect(pins.verified, ['9999', '2580']);
    expect(biometric.prompts, [l10n.biometricEnableReason]);
    expect(biometric.pin, '2580');
    expect(find.text(l10n.biometricOn), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);

    // Off forgets it.
    await tester.tap(find.byType(Switch));
    await _wait(tester);
    expect(biometric.pin, isNull);
    expect(find.text(l10n.biometricOff), findsOneWidget);
  });

  testWidgets('a cancelled fingerprint leaves it off', (tester) async {
    final biometric = FakeBiometricPin(kind: BiometricKind.fingerprint, confirms: false);
    await _open(tester, const WalletScreen(), biometric: biometric);
    await _toRow(tester, l10n);

    await tester.tap(find.text(l10n.walletBiometricFingerprint));
    await _wait(tester);
    await _typePin(tester, '2580');
    expect(biometric.pin, isNull);
    expect(find.text(l10n.biometricNotConfirmed), findsOneWidget);
  });

  testWidgets('with it on, the sheet asks for the fingerprint at once and sends', (tester) async {
    final biometric = FakeBiometricPin(kind: BiometricKind.fingerprint, pin: '2580');
    final transfers = FakeTransfers();
    await _open(tester, const SendMoneyScreen(), biometric: biometric, transfers: transfers);

    await _toPin(tester, l10n);
    expect(biometric.prompts, [l10n.biometricPayReason]);
    expect(transfers.sent.single.pin, '2580');
    expect(find.text(l10n.sendDoneTitle(formatMoney(l10n, 5000), 'Haidar K.')), findsOneWidget);
  });

  testWidgets('a cancelled fingerprint leaves the pad, and the button asks again', (tester) async {
    final biometric = FakeBiometricPin(kind: BiometricKind.fingerprint, pin: '2580', confirms: false);
    final transfers = FakeTransfers();
    await _open(tester, const SendMoneyScreen(), biometric: biometric, transfers: transfers);

    await _toPin(tester, l10n);
    expect(transfers.sent, isEmpty);
    expect(find.text(l10n.pinSheetTitle), findsOneWidget);

    biometric.confirms = true;
    await tester.tap(find.text(l10n.pinUseFingerprint));
    await _wait(tester);
    expect(biometric.prompts, hasLength(2));
    expect(transfers.sent.single.pin, '2580');
  });

  testWidgets('a kept PIN that changed meanwhile: typed this time, then kept again', (tester) async {
    final biometric = FakeBiometricPin(kind: BiometricKind.fingerprint, pin: '1357');
    final transfers = FakeTransfers(sendResults: [const Err(ForbiddenFailure())]);
    await _open(tester, const SendMoneyScreen(), biometric: biometric, transfers: transfers);

    await _toPin(tester, l10n);
    expect(transfers.sent.single.pin, '1357');
    expect(find.text(l10n.pinBiometricStale), findsOneWidget);
    expect(find.text(l10n.pinUseFingerprint), findsNothing);

    transfers.sendResults = [];
    await _typePin(tester, '2580');
    expect(transfers.sent.last.pin, '2580');
    expect(biometric.pin, '2580');
  });

  testWidgets('a new PIN replaces the kept one', (tester) async {
    final biometric = FakeBiometricPin(kind: BiometricKind.fingerprint, pin: '2580');
    await _open(tester, const WalletPinScreen(mode: PinMode.change), biometric: biometric);

    await _type(tester, '2580');
    await _type(tester, '1357');
    await _type(tester, '1357');
    expect(find.text(l10n.pinSaved), findsOneWidget);
    expect(biometric.pin, '1357');
  });
}
