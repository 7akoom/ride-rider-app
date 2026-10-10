import '../../../../core/error/result.dart';
import '../../../../core/phone/phone_number.dart';
import '../entities/otp_challenge.dart';
import '../repositories/sign_in_repository.dart';

/// Sends a login code to the phone, the first time and on "send again".
/// A failure may have a more specific message: see sendCodeProblemOf.
final class SendCode {
  const SendCode(this.signIn);

  final SignInRepository signIn;

  Future<Result<OtpChallenge>> call(PhoneNumber phone) => signIn.sendCode(phone);
}
