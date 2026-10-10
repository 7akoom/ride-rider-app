import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/error/failure.dart';
import 'package:rider_app/core/rider/display_name.dart';
import 'package:rider_app/features/onboarding/domain/problems/sign_in_problems.dart';
import 'package:rider_app/features/onboarding/domain/values/otp_code.dart';

void main() {
  group('OtpCode', () {
    test('six digits in any digit set', () {
      expect(OtpCode.tryParse('123456')?.digits, '123456');
      expect(OtpCode.tryParse('12 34 56')?.digits, '123456');
      expect(OtpCode.tryParse('١٢٣٤٥٦')?.digits, '123456');
    });

    test('anything else is refused', () {
      expect(OtpCode.tryParse('12345'), isNull);
      expect(OtpCode.tryParse('1234567'), isNull);
      expect(OtpCode.tryParse(''), isNull);
    });
  });

  group('DisplayName', () {
    test('trims and collapses spaces', () {
      expect(DisplayName.tryParse('  Salem   Suleiman ')?.value, 'Salem Suleiman');
    });

    test('too short and too long', () {
      expect(DisplayName.check(' a '), DisplayNameProblem.tooShort);
      expect(DisplayName.check('a' * (DisplayName.maxLength + 1)), DisplayNameProblem.tooLong);
      expect(DisplayName.check('a' * DisplayName.maxLength), isNull);
      expect(DisplayName.tryParse('a'), isNull);
    });

    test('counts letters, not bytes', () {
      expect(DisplayName.check('سا'), isNull);
    });
  });

  group('problems', () {
    test('sending a code', () {
      expect(sendCodeProblemOf(const InvalidInputFailure()), SendCodeProblem.invalidNumber);
      expect(sendCodeProblemOf(const RateLimitedFailure()), SendCodeProblem.tooManyRequests);
      expect(sendCodeProblemOf(const PreconditionFailure()), SendCodeProblem.cannotSendNow);
      expect(sendCodeProblemOf(const NetworkFailure()), isNull);
    });

    test('checking a code', () {
      expect(codeProblemOf(const SessionExpiredFailure()), CodeProblem.wrongCode);
      expect(codeProblemOf(const NotFoundFailure()), CodeProblem.expired);
      expect(codeProblemOf(const PreconditionFailure()), CodeProblem.expired);
      expect(codeProblemOf(const RateLimitedFailure()), CodeProblem.tooManyTries);
      expect(codeProblemOf(const ForbiddenFailure()), CodeProblem.accountBlocked);
      expect(codeProblemOf(const ServerFailure()), isNull);
    });
  });
}
