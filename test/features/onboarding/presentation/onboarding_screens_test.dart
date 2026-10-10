import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/error/failure.dart';
import 'package:rider_app/core/error/result.dart';
import 'package:rider_app/core/l10n/app_locales.dart';
import 'package:rider_app/core/l10n/l10n.dart';
import 'package:rider_app/core/phone/phone_number.dart';
import 'package:rider_app/design/components/components.dart';
import 'package:rider_app/features/onboarding/domain/entities/otp_challenge.dart';
import 'package:rider_app/features/onboarding/presentation/language/language_screen.dart';
import 'package:rider_app/features/onboarding/presentation/otp/otp_screen.dart';
import 'package:rider_app/features/onboarding/presentation/phone/phone_screen.dart';
import 'package:rider_app/features/onboarding/presentation/splash/splash_screen.dart';
import 'package:rider_app/features/onboarding/presentation/splash/start_step_provider.dart';
import 'package:rider_app/state/locale_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/pump_app.dart';
import '../fakes.dart';

final _l10n = lookupAppLocalizations(AppLocales.arabic);

Future<void> _pumpScreen(WidgetTester tester, Widget screen, List<Override> fakes) async {
  usePhoneScreen(tester);
  await pumpApp(tester, screen, inScaffold: false, settle: false, overrides: fakes);
}

/// Lets the start screen decide (it shows for a moment at least) and the app move on.
Future<void> _letStartDecide(WidgetTester tester) async {
  await tester.pump(minimumStartTime);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('start screen', () {
    testWidgets('first run opens the language screen', (tester) async {
      await _pumpScreen(tester, const SplashScreen(),
          onboardingFakes(preferences: FakePreferences(chosen: false)));
      await _letStartDecide(tester);

      expect(find.byType(LanguageScreen), findsOneWidget);
    });

    testWidgets('no session opens the phone screen', (tester) async {
      await _pumpScreen(tester, const SplashScreen(),
          onboardingFakes(signIn: FakeSignIn(session: false)));
      await _letStartDecide(tester);

      expect(find.byType(PhoneScreen), findsOneWidget);
    });

    testWidgets('offline: the message and "try again", the session kept', (tester) async {
      final signIn = FakeSignIn();
      await _pumpScreen(tester, const SplashScreen(), onboardingFakes(
        signIn: signIn,
        accounts: FakeAccounts(const Err(NetworkFailure())),
      ));
      await _letStartDecide(tester);

      expect(find.text(_l10n.errorNoConnection), findsOneWidget);
      expect(find.text(_l10n.actionRetry), findsOneWidget);
      expect(signIn.forgotten, isFalse);
    });
  });

  testWidgets('language: picking switches the app, continue opens the phone screen',
      (tester) async {
    await _pumpScreen(tester, const LanguageScreen(), onboardingFakes());
    await tester.pumpAndSettle();

    await tester.tap(find.text(_l10n.languageNameEnglish));
    await tester.pump();
    final container = ProviderScope.containerOf(tester.element(find.byType(LanguageScreen)));
    expect(container.read(localeProvider).languageCode, 'en');

    await tester.tap(find.text(_l10n.actionContinue));
    await tester.pumpAndSettle();
    expect(find.byType(PhoneScreen), findsOneWidget);
  });

  group('phone screen', () {
    AppButton sendButton(WidgetTester tester) =>
        tester.widget<AppButton>(find.widgetWithText(AppButton, _l10n.phoneSendCode));

    testWidgets('the button works only for a valid number, then opens the code screen',
        (tester) async {
      await _pumpScreen(tester, const PhoneScreen(), onboardingFakes());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '0750 123');
      await tester.pump();
      expect(sendButton(tester).onPressed, isNull);

      await tester.enterText(find.byType(TextField), '0750 123 4567');
      await tester.pump();
      await tester.tap(find.text(_l10n.phoneSendCode));
      await tester.pumpAndSettle();

      expect(find.byType(OtpScreen), findsOneWidget);
    });

    testWidgets('a refusal is shown as a sentence, never a technical error', (tester) async {
      await _pumpScreen(tester, const PhoneScreen(),
          onboardingFakes(signIn: FakeSignIn(sendFailure: const RateLimitedFailure())));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '07501234567');
      await tester.pump();
      await tester.tap(find.text(_l10n.phoneSendCode));
      await tester.pumpAndSettle();

      expect(find.text(_l10n.sendCodeTooMany), findsOneWidget);
      expect(find.byType(OtpScreen), findsNothing);
    });
  });

  testWidgets('code screen: a wrong code says so and empties the boxes', (tester) async {
    final challenge = OtpChallenge(
      id: 'c1',
      phone: PhoneNumber.tryParse('07501234567')!,
      expiresIn: const Duration(minutes: 5),
    );
    await _pumpScreen(tester, OtpScreen(challenge: challenge), onboardingFakes(
      signIn: FakeSignIn(confirmResult: const Err(SessionExpiredFailure())),
    ));
    await tester.pump();

    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    await tester.pump();

    expect(find.text(_l10n.codeWrong), findsOneWidget);
    expect(find.text('1'), findsNothing);
  });
}
