import '../../../core/network/api_client.dart';

/// The gateway's routes after a trip: its settlement, the rating and the tip. Failures
/// are thrown as ApiException; the repository turns them into failures.
class TripEndApi {
  TripEndApi(this._client);

  final ApiClient _client;

  Future<JsonMap> settlement(String riderId, String tripId) => _client.get(
        '/v1/wallets/${Uri.encodeComponent(riderId)}/trips/${Uri.encodeComponent(tripId)}/settlement',
        query: const <String, dynamic>{'ownerType': 'OWNER_TYPE_RIDER'},
      );

  Future<JsonMap> rate(String tripId, JsonMap body) =>
      _client.post('/v1/trips/${Uri.encodeComponent(tripId)}:rate', body: body);

  Future<JsonMap> tip(String riderId, String tripId, JsonMap body) => _client.post(
        '/v1/wallets/${Uri.encodeComponent(riderId)}/trips/${Uri.encodeComponent(tripId)}/tip',
        body: body,
      );
}
