import '../../../../core/error/result.dart';
import '../entities/otp_challenge.dart';
import '../repositories/sign_in_repository.dart';
import '../values/otp_code.dart';

/// Signs the signed-in rider in again with a fresh code, without leaving the app: a
/// forgotten wallet PIN may be set anew only moments after signing in. A failure is
/// about the code (see codeProblemOf).
final class ConfirmCodeAgain {
  const ConfirmCodeAgain(this.signIn);

  final SignInRepository signIn;

  Future<Result<void>> call(OtpChallenge challenge, OtpCode code) => signIn.confirmCodeAgain(challenge, code);
}
