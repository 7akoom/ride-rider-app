import '../../../core/network/api_client.dart';

/// The gateway's routes for ordering a ride: prices, the wallet, the trip request.
/// Failures are thrown as ApiException; the repository turns them into failures.
class RidesApi {
  RidesApi(this._client);

  final ApiClient _client;

  Future<JsonMap> quotes(JsonMap body) => _client.post('/v1/fare-quotes', body: body);

  Future<JsonMap> wallet(String riderId) => _client.get(
        '/v1/wallets/${Uri.encodeComponent(riderId)}',
        query: <String, dynamic>{'ownerType': 'OWNER_TYPE_RIDER'},
      );

  Future<JsonMap> requestTrip(JsonMap body) => _client.post('/v1/trips', body: body);
}
