import '../../../../core/error/result.dart';
import '../../../../core/phone/phone_number.dart';
import '../entities/otp_challenge.dart';
import '../values/otp_code.dart';

/// Signing in with a code sent to the phone, and the session that results.
abstract interface class SignInRepository {
  /// Asks the backend to send a login code to [phone].
  Future<Result<OtpChallenge>> sendCode(PhoneNumber phone);

  /// Checks [code] against [challenge]. On success the session is stored securely.
  Future<Result<void>> confirmCode(OtpChallenge challenge, OtpCode code);

  /// Whether a session is stored on the phone (not yet whether the backend accepts it).
  Future<bool> hasSession();

  /// Forgets the stored session. The install's device id stays.
  Future<void> forgetSession();
}
