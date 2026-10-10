import '../../../core/error/failure.dart';
import '../../../core/error/failure_mapper.dart';
import '../../../core/error/guard.dart';
import '../../../core/error/result.dart';
import '../../../core/location/geo_point.dart';
import '../../../core/network/json.dart';
import '../domain/repositories/places_repository.dart';
import 'booking_api.dart';

final class PlacesRepositoryImpl implements PlacesRepository {
  PlacesRepositoryImpl(this._api);

  final BookingApi _api;

  @override
  Future<Result<String?>> addressAt(GeoPoint point, {required String languageCode}) =>
      guard(() async {
        try {
          final place = objectAt(await _api.reverse(point, languageCode), 'place');
          if (place == null) {
            return null;
          }

          final name = place['name'];
          if (name is String && name.trim().isNotEmpty) {
            return name.trim();
          }

          final full = place['displayName'];

          return full is String && full.trim().isNotEmpty
              ? full.split(',').first.trim()
              : null;
        } on Object catch (error) {
          // Nothing on the map there: not a failure.
          if (mapToFailure(error) is NotFoundFailure) {
            return null;
          }

          rethrow;
        }
      });
}
