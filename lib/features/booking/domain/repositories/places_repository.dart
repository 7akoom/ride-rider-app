import '../../../../core/error/result.dart';
import '../../../../core/location/geo_point.dart';

/// Places on the map.
abstract interface class PlacesRepository {
  /// What is at [point], in [languageCode]; Ok(null) when the map has nothing there.
  Future<Result<String?>> addressAt(GeoPoint point, {required String languageCode});
}
