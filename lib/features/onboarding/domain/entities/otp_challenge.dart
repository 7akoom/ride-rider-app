import '../../../../core/phone/phone_number.dart';

/// A login code on its way to the rider: what the typed code is checked against.
final class OtpChallenge {
  const OtpChallenge({
    required this.id,
    required this.phone,
    required this.expiresIn,
  });

  final String id;

  /// Where the code was sent, to show it on the code screen and to send it again.
  final PhoneNumber phone;

  /// How long the code works.
  final Duration expiresIn;

  /// How long to wait before asking for another code. The backend refuses earlier
  /// requests (OTP_REQUEST_COOLDOWN, 60 seconds by default).
  static const Duration resendAfter = Duration(seconds: 60);
}
