import '../../../core/network/api_client.dart';

/// The gateway's money request routes for the rider. Failures are thrown as
/// ApiException; the repository turns them into failures.
class MoneyRequestApi {
  MoneyRequestApi(this._client);

  final ApiClient _client;

  String _path(String riderId) => '/v1/wallets/${Uri.encodeComponent(riderId)}/money-requests';

  String _one(String riderId, String code) => '${_path(riderId)}/${Uri.encodeComponent(code)}';

  Future<JsonMap> create(
    String riderId, {
    required String payerPhone,
    required String amount,
    required String note,
    required String key,
  }) =>
      _client.post(_path(riderId), body: {
        'payerPhone': payerPhone,
        'amount': amount,
        'note': note,
        'idempotencyKey': key,
      });

  Future<JsonMap> list(String riderId, {required String role, String status = '', int pageSize = 50}) =>
      _client.get(_path(riderId), query: {
        'role': role,
        if (status.isNotEmpty) 'status': status,
        'pageSize': pageSize,
      });

  Future<JsonMap> get(String riderId, String code) => _client.get(_one(riderId, code));

  Future<JsonMap> pay(String riderId, String code, String pin) =>
      _client.post('${_one(riderId, code)}:pay', body: {'pin': pin});

  Future<JsonMap> decline(String riderId, String code) => _client.post('${_one(riderId, code)}:decline');

  Future<JsonMap> cancel(String riderId, String code) => _client.post('${_one(riderId, code)}:cancel');
}
