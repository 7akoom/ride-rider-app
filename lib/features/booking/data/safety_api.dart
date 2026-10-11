import '../../../core/network/api_client.dart';

/// The gateway's routes for safety on a trip: share links, the alarm and the safety
/// ticket. Failures are thrown as ApiException; the repository turns them into failures.
class SafetyApi {
  SafetyApi(this._client);

  final ApiClient _client;

  Future<JsonMap> share(String tripId) =>
      _client.post('/v1/trips/${Uri.encodeComponent(tripId)}/shares', body: const <String, dynamic>{});

  Future<JsonMap> stopSharing(String tripId) =>
      _client.post('/v1/trips/${Uri.encodeComponent(tripId)}/shares:stop', body: const <String, dynamic>{});

  Future<JsonMap> alarm(String tripId, JsonMap body) =>
      _client.post('/v1/trips/${Uri.encodeComponent(tripId)}:sos', body: body);

  Future<JsonMap> ticket(JsonMap body) => _client.post('/v1/support/tickets', body: body);
}
