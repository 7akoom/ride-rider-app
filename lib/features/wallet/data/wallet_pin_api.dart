import '../../../core/network/api_client.dart';

/// The gateway's wallet PIN route (identity-service). Failures are thrown as
/// ApiException; the repository turns them into failures.
class WalletPinApi {
  WalletPinApi(this._client);

  final ApiClient _client;

  static const String _path = '/v1/me/wallet-pin';

  Future<JsonMap> status() => _client.get(_path);

  Future<JsonMap> verify(String pin) => _client.post('$_path:verify', body: {'pin': pin});

  Future<JsonMap> set({required String newPin, String? currentPin}) => _client.put(
        _path,
        body: {
          'newPin': newPin,
          if (currentPin != null) 'currentPin': currentPin,
        },
      );
}
