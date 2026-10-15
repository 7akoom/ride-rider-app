import '../../../core/network/api_client.dart';

/// The gateway's transfer routes for the rider. Failures are thrown as ApiException;
/// the repository turns them into failures.
class TransferApi {
  TransferApi(this._client);

  final ApiClient _client;

  String _path(String riderId) => '/v1/wallets/${Uri.encodeComponent(riderId)}';

  Future<JsonMap> options(String riderId) => _client.get('${_path(riderId)}/transfer-options');

  Future<JsonMap> lookup(String riderId, String phone) =>
      _client.post('${_path(riderId)}/transfer-recipients:lookup', body: {'phone': phone});

  Future<JsonMap> list(String riderId, {int pageSize = 50}) =>
      _client.get('${_path(riderId)}/transfers', query: {'pageSize': pageSize});

  Future<JsonMap> send(
    String riderId, {
    required String phone,
    required String amount,
    required String note,
    required String pin,
    required String key,
  }) =>
      _client.post('${_path(riderId)}/transfers', body: {
        'recipientPhone': phone,
        'amount': amount,
        'note': note,
        'pin': pin,
        'idempotencyKey': key,
      });
}
