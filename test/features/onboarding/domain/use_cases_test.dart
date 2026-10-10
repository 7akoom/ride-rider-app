import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/error/failure.dart';
import 'package:rider_app/core/error/result.dart';
import 'package:rider_app/core/phone/phone_number.dart';
import 'package:rider_app/core/rider/rider_account.dart';
import 'package:rider_app/features/onboarding/domain/entities/next_step.dart';
import 'package:rider_app/features/onboarding/domain/entities/otp_challenge.dart';
import 'package:rider_app/features/onboarding/domain/use_cases/confirm_code.dart';
import 'package:rider_app/features/onboarding/domain/use_cases/decide_start.dart';
import 'package:rider_app/features/onboarding/domain/values/otp_code.dart';

import '../fakes.dart';

Future<Result<NextStep>> _start({
  bool chosen = true,
  bool session = true,
  Result<RiderAccount?> found = const Ok(someone),
  FakeSignIn? signIn,
}) {
  return DecideStart(
    preferences: FakePreferences(chosen: chosen),
    signIn: signIn ?? FakeSignIn(session: session),
    accounts: FakeAccounts(found),
    accountStep: accountStepWith(),
  ).call();
}

NextStep? _step(Result<NextStep> result) => result.fold((v) => v, (_) => null);

void main() {
  group('DecideStart', () {
    test('first run: the language screen', () async {
      expect(_step(await _start(chosen: false)), NextStep.chooseLanguage);
    });

    test('no session: the phone screen', () async {
      expect(_step(await _start(session: false)), NextStep.enterPhone);
    });

    test('signed in without a profile: the name screen', () async {
      expect(_step(await _start(found: const Ok(null))), NextStep.enterName);
    });

    test('signed in with a profile: the app', () async {
      expect(_step(await _start()), NextStep.home);
    });

    test('a refused session is forgotten and leads to sign-in', () async {
      final signIn = FakeSignIn();
      final result = await _start(signIn: signIn, found: const Err(SessionExpiredFailure()));

      expect(_step(result), NextStep.enterPhone);
      expect(signIn.forgotten, isTrue);
    });

    test('no connection keeps the session and reports the failure', () async {
      final signIn = FakeSignIn();
      final result = await _start(signIn: signIn, found: const Err(NetworkFailure()));

      expect(result, isA<Err<NextStep>>());
      expect(signIn.forgotten, isFalse);
    });
  });

  group('ConfirmCode', () {
    final challenge = OtpChallenge(
      id: 'c1',
      phone: PhoneNumber.tryParse('07701234567')!,
      expiresIn: const Duration(minutes: 5),
    );
    final code = OtpCode.tryParse('123456')!;

    Future<Result<NextStep>> confirm(Result<void> verified, Result<RiderAccount?> found) =>
        ConfirmCode(
          signIn: FakeSignIn(confirmResult: verified),
          accounts: FakeAccounts(found),
          accountStep: accountStepWith(),
        ).call(challenge, code);

    test('a refused code is returned as the failure', () async {
      final result = await confirm(const Err(SessionExpiredFailure()), const Ok(someone));

      expect(result.fold((_) => null, (f) => f), isA<SessionExpiredFailure>());
    });

    test('new rider: the name screen; known rider: the app', () async {
      expect(_step(await confirm(const Ok(null), const Ok(null))), NextStep.enterName);
      expect(_step(await confirm(const Ok(null), const Ok(someone))), NextStep.home);
    });

    test('profile check failed after sign-in: check again, not a code error', () async {
      final result = await confirm(const Ok(null), const Err(NetworkFailure()));

      expect(_step(result), NextStep.checkAgain);
    });
  });
}
