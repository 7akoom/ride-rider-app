import '../../../core/location/geo_point.dart';
import '../../../core/network/api_client.dart';

/// The gateway's map and saved-address routes used while booking. Failures are thrown
/// as ApiException; the repositories turn them into failures.
class BookingApi {
  BookingApi(this._client);

  final ApiClient _client;

  Future<JsonMap> savedAddresses(String riderId) =>
      _client.get('/v1/riders/${Uri.encodeComponent(riderId)}/addresses');

  Future<JsonMap> reverse(GeoPoint point, String languageCode) => _client.get(
        '/v1/places:reverse',
        query: <String, dynamic>{
          'coordinates.latitude': point.latitude,
          'coordinates.longitude': point.longitude,
          'language': languageCode,
        },
      );
}
