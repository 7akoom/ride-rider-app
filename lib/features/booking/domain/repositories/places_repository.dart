import '../../../../core/error/result.dart';
import '../../../../core/location/geo_point.dart';
import '../entities/spot.dart';

/// Places on the map.
abstract interface class PlacesRepository {
  /// What is at [point], in [languageCode]; Ok(null) when the map has nothing there.
  Future<Result<String?>> addressAt(GeoPoint point, {required String languageCode});

  /// Places matching [query] (at least 2 characters), best match first; [near] ranks
  /// close places higher.
  Future<Result<List<Spot>>> search(
    String query, {
    GeoPoint? near,
    required String languageCode,
  });

  /// The places staff chose (airports, malls...), closest to [near] first.
  Future<Result<List<Spot>>> featured({GeoPoint? near, required String languageCode});
}
