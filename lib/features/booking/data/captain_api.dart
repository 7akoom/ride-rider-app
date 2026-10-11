import '../../../core/network/api_client.dart';

/// The gateway's routes about the captain of the rider's trip. Failures are thrown as
/// ApiException; the repository turns them into failures.
class CaptainApi {
  CaptainApi(this._client);

  final ApiClient _client;

  Future<JsonMap> captain(String tripId) =>
      _client.get('/v1/trips/${Uri.encodeComponent(tripId)}/driver');

  Future<JsonMap> position(String tripId) =>
      _client.get('/v1/trips/${Uri.encodeComponent(tripId)}/driver-location');
}
