import '../../../core/network/api_client.dart';

/// The gateway's routes for ordering a ride and following it: prices, the wallet,
/// the trip request, its state, cancelling, and booking ahead. Failures are thrown as ApiException;
/// the repository turns them into failures.
class RidesApi {
  RidesApi(this._client);

  final ApiClient _client;

  Future<JsonMap> quotes(JsonMap body) => _client.post('/v1/fare-quotes', body: body);

  Future<JsonMap> wallet(String riderId) => _client.get(
        '/v1/wallets/${Uri.encodeComponent(riderId)}',
        query: <String, dynamic>{'ownerType': 'OWNER_TYPE_RIDER'},
      );

  Future<JsonMap> requestTrip(JsonMap body) => _client.post('/v1/trips', body: body);

  Future<JsonMap> trip(String id) => _client.get('/v1/trips/${Uri.encodeComponent(id)}');

  Future<JsonMap> activeTrip(String riderId) =>
      _client.get('/v1/trips:active', query: <String, dynamic>{'riderId': riderId});

  Future<JsonMap> cancelTrip(String id, String reason) => _client.post(
        '/v1/trips/${Uri.encodeComponent(id)}:cancel',
        body: <String, dynamic>{'reason': reason},
      );

  Future<JsonMap> scheduleTrip(JsonMap body) => _client.post('/v1/scheduled-trips', body: body);

  Future<JsonMap> cancelScheduled(String id, String riderId) => _client.post(
        '/v1/scheduled-trips/${Uri.encodeComponent(id)}:cancel',
        body: <String, dynamic>{'riderId': riderId},
      );
}
