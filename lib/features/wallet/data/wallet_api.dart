import '../../../core/network/api_client.dart';

/// The gateway's wallet routes for the rider. Failures are thrown as ApiException; the
/// repository turns them into failures.
class WalletApi {
  WalletApi(this._client);

  final ApiClient _client;

  static const Map<String, dynamic> _rider = {'ownerType': 'OWNER_TYPE_RIDER'};

  String _path(String riderId) => '/v1/wallets/${Uri.encodeComponent(riderId)}';

  Future<JsonMap> wallet(String riderId) => _client.get(_path(riderId), query: _rider);

  Future<JsonMap> dues(String riderId) => _client.get('${_path(riderId)}/dues');

  Future<JsonMap> transactions(String riderId, int limit) =>
      _client.get('${_path(riderId)}/transactions', query: {..._rider, 'limit': limit});

  Future<JsonMap> statement(String riderId, Map<String, dynamic> query) =>
      _client.get('${_path(riderId)}/statement', query: {..._rider, ...query});
}
