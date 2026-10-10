import '../../../core/error/failure.dart';
import '../../../core/error/guard.dart';
import '../../../core/error/result.dart';
import '../../../core/location/geo_point.dart';
import '../../../core/network/json.dart';
import '../../../core/security/session_storage.dart';
import '../domain/entities/saved_place.dart';
import '../domain/repositories/saved_places_repository.dart';
import 'booking_api.dart';

final class SavedPlacesRepositoryImpl implements SavedPlacesRepository {
  SavedPlacesRepositoryImpl(this._api);

  final BookingApi _api;

  @override
  Future<Result<List<SavedPlace>>> list() => guard(() async {
        final riderId = await SessionStorage.readRiderId();
        if (riderId == null || riderId.isEmpty) {
          throw const SessionExpiredFailure();
        }

        final items = (await _api.savedAddresses(riderId))['addresses'];
        if (items is! List) {
          return const <SavedPlace>[];
        }

        return [
          for (final item in items)
            if (item is Map) _placeOf(decodeJsonObject(item)),
        ];
      });

  static SavedPlace _placeOf(JsonMap json) {
    final label = json['label'];
    final address = json['address'];

    return SavedPlace(
      id: requiredText(json, 'id'),
      kind: switch (json['kind']) {
        'SAVED_ADDRESS_KIND_HOME' => SavedPlaceKind.home,
        'SAVED_ADDRESS_KIND_WORK' => SavedPlaceKind.work,
        _ => SavedPlaceKind.other,
      },
      label: label is String ? label : '',
      address: address is String ? address : '',
      point: GeoPoint.fromJson(json['coordinates']),
    );
  }
}
