import '../../../core/error/guard.dart';
import '../../../core/error/result.dart';
import '../../../core/network/json.dart';
import '../../../core/phone/phone_number.dart';
import '../../../core/security/session_storage.dart';
import '../domain/entities/otp_challenge.dart';
import '../domain/repositories/sign_in_repository.dart';
import '../domain/values/otp_code.dart';
import 'client_info.dart';
import 'sign_in_api.dart';

final class SignInRepositoryImpl implements SignInRepository {
  SignInRepositoryImpl(this._api, {ClientInfo? client})
      : _client = client ?? ClientInfo.current();

  final SignInApi _api;
  final ClientInfo _client;

  /// Used when the backend leaves the lifetime out (its default is five minutes).
  static const Duration _defaultLifetime = Duration(minutes: 5);

  @override
  Future<Result<OtpChallenge>> sendCode(PhoneNumber phone) => guard(() async {
        final json = await _api.requestCode(phone.e164);
        final seconds = json['expiresInSeconds'];

        return OtpChallenge(
          id: requiredText(json, 'challengeId'),
          phone: phone,
          expiresIn: seconds is num && seconds > 0
              ? Duration(seconds: seconds.toInt())
              : _defaultLifetime,
        );
      });

  @override
  Future<Result<void>> confirmCode(OtpChallenge challenge, OtpCode code) =>
      guard(() async {
        final json = await _api.verifyCode(
          challengeId: challenge.id,
          code: code.digits,
          deviceId: await SessionStorage.deviceId(),
          client: _client,
        );

        // All three or nothing: a half-stored session would look signed in and fail.
        final identityId = requiredText(json, 'identityId');
        final accessToken = requiredText(json, 'accessToken');
        final refreshToken = requiredText(json, 'refreshToken');

        await SessionStorage.clear();
        await SessionStorage.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
          identityId: identityId,
        );
      });

  @override
  Future<bool> hasSession() async {
    try {
      final refreshToken = await SessionStorage.readRefreshToken();
      final identityId = await SessionStorage.readIdentityId();

      return refreshToken != null && identityId != null;
    } catch (_) {
      // Unreadable storage (for example after a restore to another phone): no session.
      return false;
    }
  }

  @override
  Future<void> forgetSession() async {
    try {
      await SessionStorage.clear();
    } catch (_) {
      // Nothing more can be done; the next sign-in overwrites whatever is left.
    }
  }
}
