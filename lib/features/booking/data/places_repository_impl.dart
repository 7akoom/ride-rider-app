import '../../../core/error/failure.dart';
import '../../../core/error/failure_mapper.dart';
import '../../../core/error/guard.dart';
import '../../../core/error/result.dart';
import '../../../core/location/geo_point.dart';
import '../../../core/network/json.dart';
import '../domain/entities/spot.dart';
import '../domain/repositories/places_repository.dart';
import 'booking_api.dart';
import 'spot_json.dart';

final class PlacesRepositoryImpl implements PlacesRepository {
  PlacesRepositoryImpl(this._api);

  final BookingApi _api;

  @override
  Future<Result<String?>> addressAt(GeoPoint point, {required String languageCode}) =>
      guard(() async {
        try {
          final place = objectAt(await _api.reverse(point, languageCode), 'place');

          return place == null ? null : SpotJson.fromSearch(place).title;
        } on Object catch (error) {
          // Nothing on the map there: not a failure.
          if (mapToFailure(error) is NotFoundFailure) {
            return null;
          }

          rethrow;
        }
      });

  @override
  Future<Result<List<Spot>>> search(
    String query, {
    GeoPoint? near,
    required String languageCode,
  }) =>
      guard(() async => _spots(
            await _api.search(query, near, languageCode),
            SpotJson.fromSearch,
          ));

  @override
  Future<Result<List<Spot>>> featured({GeoPoint? near, required String languageCode}) =>
      guard(() async => _spots(
            await _api.curated(near),
            (json) => SpotJson.fromCurated(json, languageCode),
          ));

  /// The `places` list of an answer; places without a position are left out.
  static List<Spot> _spots(JsonMap answer, Spot Function(JsonMap) read) {
    final items = answer['places'];
    if (items is! List) {
      return const <Spot>[];
    }

    return [
      for (final item in items)
        if (item is Map) read(decodeJsonObject(item)),
    ].where((spot) => !spot.point.isEmpty).toList();
  }
}
