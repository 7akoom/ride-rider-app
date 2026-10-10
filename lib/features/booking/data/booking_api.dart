import '../../../core/location/geo_point.dart';
import '../../../core/network/api_client.dart';

/// The gateway's map and saved-address routes used while booking. Failures are thrown
/// as ApiException; the repositories turn them into failures.
class BookingApi {
  BookingApi(this._client);

  final ApiClient _client;

  static const int searchLimit = 10;
  static const int featuredPageSize = 20;

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

  Future<JsonMap> search(String query, GeoPoint? near, String languageCode) =>
      _client.get(
        '/v1/places:search',
        query: <String, dynamic>{
          'query': query,
          'limit': searchLimit,
          'language': languageCode,
          ..._near(near),
        },
      );

  /// The places staff chose (airports, malls...).
  Future<JsonMap> curated(GeoPoint? near) => _client.get(
        '/v1/places',
        query: <String, dynamic>{'page_size': featuredPageSize, ..._near(near)},
      );

  Future<JsonMap> route(List<GeoPoint> points) => _client.post(
        '/v1/routes:compute',
        body: <String, dynamic>{
          'origin': points.first.toJson(),
          'destination': points.last.toJson(),
          if (points.length > 2)
            'via': [for (final p in points.sublist(1, points.length - 1)) p.toJson()],
        },
      );

  static Map<String, dynamic> _near(GeoPoint? near) => near == null
      ? const {}
      : {'near.latitude': near.latitude, 'near.longitude': near.longitude};
}
