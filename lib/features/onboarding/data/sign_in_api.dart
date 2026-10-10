import '../../../core/network/api_client.dart';
import 'client_info.dart';

/// The gateway's login routes. They take no access token. Failures are thrown as
/// ApiException; the repository turns them into failures.
class SignInApi {
  SignInApi(this._client);

  final ApiClient _client;

  Future<JsonMap> requestCode(String e164Phone) => _client.post(
        '/v1/auth/otp:request',
        auth: false,
        body: <String, dynamic>{
          'identifier': <String, dynamic>{
            'type': 'IDENTIFIER_TYPE_PHONE',
            'value': e164Phone,
          },
        },
      );

  Future<JsonMap> verifyCode({
    required String challengeId,
    required String code,
    required String deviceId,
    required ClientInfo client,
  }) =>
      _client.post(
        '/v1/auth/otp:verify',
        auth: false,
        body: <String, dynamic>{
          'challengeId': challengeId,
          'code': code,
          'clientId': client.clientId,
          'deviceId': deviceId,
          'deviceName': client.deviceName,
          'platform': client.platform,
          'appVersion': client.appVersion,
        },
      );
}
