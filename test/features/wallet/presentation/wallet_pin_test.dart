import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/format/time_format.dart';
import 'package:rider_app/core/l10n/app_locales.dart';
import 'package:rider_app/core/l10n/l10n.dart';
import 'package:rider_app/features/onboarding/onboarding_providers.dart';
import 'package:rider_app/features/wallet/presentation/pin_reset_screen.dart';
import 'package:rider_app/features/wallet/presentation/wallet_pin_controller.dart';
import 'package:rider_app/features/wallet/presentation/wallet_pin_screen.dart';
import 'package:rider_app/features/wallet/presentation/wallet_screen.dart';
import 'package:rider_app/state/api_providers.dart';

import '../../../helpers/pump_app.dart';
import '../../booking/fakes.dart';
import '../../onboarding/fakes.dart' show FakeSignIn;

Future<void> _wait(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(milliseconds: 600));
}

Future<void> _open(
  WidgetTester tester,
  Widget screen, {
  required FakeWalletPin pins,
  FakeSignIn? signIn,
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
      ...bookingFakes(walletPin: pins),
      signInRepositoryProvider.overrideWithValue(signIn ?? FakeSignIn()),
      myPhoneProvider.overrideWith((ref) async => '+9647501234567'),
    ],
  );
  await _wait(tester);
}

/// Types [pin] on the number pad.
Future<void> _type(WidgetTester tester, String pin) async {
  for (final digit in pin.split('')) {
    await tester.tap(find.text(digit));
    await tester.pump();
  }
  await _wait(tester);
}

void main() {
  final l10n = lookupAppLocalizations(AppLocales.arabic);

  testWidgets('a first PIN: weak ones and a mismatch are caught, then it is saved', (tester) async {
    final pins = FakeWalletPin();
    await _open(tester, const WalletPinScreen(mode: PinMode.create), pins: pins);
    expect(find.text(l10n.pinCreateTitle), findsOneWidget);

    await _type(tester, '1234');
    expect(find.text(l10n.pinWeak), findsOneWidget);
    expect(find.text(l10n.pinCreateTitle), findsOneWidget);

    await _type(tester, '2580');
    expect(find.text(l10n.pinConfirmTitle), findsOneWidget);
    expect(find.text(l10n.pinWeak), findsNothing);

    await _type(tester, '2581');
    expect(find.text(l10n.pinMismatch), findsOneWidget);
    expect(find.text(l10n.pinCreateTitle), findsOneWidget);

    await _type(tester, '2580');
    await _type(tester, '2580');
    expect(pins.sets, [('2580', null)]);
    expect(find.text(l10n.pinSaved), findsOneWidget);
    expect(find.text(l10n.pinDone), findsOneWidget);
  });

  testWidgets('a change checks the current PIN at once; a wrong one says how many tries are left', (tester) async {
    final pins = FakeWalletPin(pin: '2580');
    await _open(tester, const WalletPinScreen(mode: PinMode.change), pins: pins);
    expect(find.text(l10n.pinCurrentTitle), findsOneWidget);
    expect(find.text(l10n.pinForgot), findsOneWidget);

    await _type(tester, '9999');
    expect(pins.verified, ['9999']);
    expect(find.text(l10n.pinWrongCurrent(4)), findsOneWidget);
    expect(find.text(l10n.pinCurrentTitle), findsOneWidget);
    expect(pins.sets, isEmpty);

    await _type(tester, '2580');
    expect(find.text(l10n.pinNewTitle), findsOneWidget);
    await _type(tester, '1357');
    await _type(tester, '1357');
    expect(pins.sets, [('1357', '2580')]);
    expect(find.text(l10n.pinSaved), findsOneWidget);
  });

  testWidgets('five wrong current PINs lock it, and only the reset is left', (tester) async {
    final pins = FakeWalletPin(pin: '2580');
    await _open(tester, const WalletPinScreen(mode: PinMode.change), pins: pins);

    for (final wrong in ['1111', '2222', '3333', '4444']) {
      await _type(tester, wrong);
    }
    expect(find.text(l10n.pinWrongCurrent(1)), findsOneWidget);

    await _type(tester, '5555');
    expect(find.text(l10n.pinLocked(formatClock(l10n, pins.lockedUntil!))), findsOneWidget);
    expect(find.text(l10n.pinForgot), findsOneWidget);
    expect(find.text('5'), findsNothing);
  });

  testWidgets('a locked PIN offers only the reset', (tester) async {
    final until = DateTime.now().add(const Duration(minutes: 15));
    final pins = FakeWalletPin(pin: '2580', lockedUntil: until, attemptsLeft: 0);
    await _open(tester, WalletPinScreen(mode: PinMode.change, lockedUntil: until), pins: pins);

    expect(find.text(l10n.pinLocked(formatClock(l10n, until))), findsOneWidget);
    expect(find.text(l10n.pinForgot), findsOneWidget);
    expect(find.text('5'), findsNothing);
  });

  testWidgets('the wallet shows whether there is a PIN and opens its screen', (tester) async {
    await _open(tester, const WalletScreen(), pins: FakeWalletPin());

    await tester.scrollUntilVisible(find.text(l10n.walletPinRow), 300, scrollable: find.byType(Scrollable).first);
    expect(find.text(l10n.walletPinNotSet), findsOneWidget);

    await tester.tap(find.text(l10n.walletPinRow));
    await _wait(tester);
    expect(find.text(l10n.pinCreateTitle), findsOneWidget);
  });

  testWidgets('a forgotten PIN: a code signs the rider in again, then a new PIN without the old', (tester) async {
    final pins = FakeWalletPin(pin: '2580', freshSignIn: true);
    final signIn = FakeSignIn();
    await _open(tester, const PinResetScreen(), pins: pins, signIn: signIn);

    expect(signIn.codesSent, 1);
    expect(find.textContaining('750 123 4567'), findsOneWidget);

    await tester.enterText(find.byType(EditableText), '123456');
    await _wait(tester);
    expect(signIn.confirmedAgain, ['123456']);
    expect(find.text(l10n.pinNewTitle), findsOneWidget);
    expect(find.text(l10n.pinForgot), findsNothing);

    await _type(tester, '1357');
    await _type(tester, '1357');
    expect(pins.sets, [('1357', null)]);
    expect(find.text(l10n.pinSaved), findsOneWidget);
  });

  for (final locale in AppLocales.all) {
    testWidgets('the PIN screens fit a phone: ${locale.languageCode}', (tester) async {
      await _open(tester, const WalletPinScreen(mode: PinMode.change), pins: FakeWalletPin(pin: '2580'), locale: locale);
      expect(tester.takeException(), isNull);

      await _type(tester, '9999');
      expect(tester.takeException(), isNull);

      await _type(tester, '2580');
      await _type(tester, '1357');
      await _type(tester, '1357');
      expect(tester.takeException(), isNull);
    });
  }
}
