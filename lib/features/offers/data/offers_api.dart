import '../../../core/network/api_client.dart';

/// The gateway's offer routes for the rider. Failures are thrown as ApiException; the
/// repository turns them into failures.
class OffersApi {
  OffersApi(this._client);

  final ApiClient _client;

  String _path(String riderId) => '/v1/riders/${Uri.encodeComponent(riderId)}/offers';

  Future<JsonMap> offers(String riderId) => _client.get(_path(riderId));

  Future<JsonMap> check(String riderId, String code) => _client.post('${_path(riderId)}:check', body: {'code': code});
}
