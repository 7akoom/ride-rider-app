import '../../../core/error/guard.dart';
import '../../../core/error/result.dart';
import '../../../core/location/geo_point.dart';
import '../../../core/network/api_client.dart';
import '../../../core/rider/rider_id.dart';
import '../domain/recent_destination.dart';

/// GET /v1/riders/{id}/recent-destinations (trip-service).
final class RecentDestinationsRepositoryImpl implements RecentDestinationsRepository {
  RecentDestinationsRepositoryImpl(this._client);

  final ApiClient _client;

  @override
  Future<Result<List<RecentDestination>>> recent({int limit = 1}) => guard(() async {
        final riderId = await riderIdOrSignIn();
        final json = await _client.get(
          '/v1/riders/${Uri.encodeComponent(riderId)}/recent-destinations',
          query: <String, dynamic>{'limit': limit},
        );

        return recentDestinationsOf(json);
      });
}

List<RecentDestination> recentDestinationsOf(JsonMap json) {
  final items = json['destinations'];

  return [
    if (items is List)
      for (final item in items)
        if (item is Map && item['coordinates'] is Map)
          RecentDestination(
            point: GeoPoint.fromJson(item['coordinates']),
            address: item['address'] is String ? (item['address'] as String).trim() : '',
            lastTripAt: item['lastTripAt'] is String ? DateTime.tryParse(item['lastTripAt'] as String)?.toLocal() : null,
          ),
  ];
}
