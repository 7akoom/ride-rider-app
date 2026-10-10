import '../../../../core/error/result.dart';
import '../../../../core/location/location_access.dart';
import '../entities/pickup_spot.dart';
import '../repositories/places_repository.dart';

/// Where the rider is, to be picked up there. Ok(null) without a position (location
/// not allowed, off, or not found). A position without an address is still a pickup:
/// failing to name it is not a reason to fail.
final class FindPickup {
  const FindPickup({required this.location, required this.places});

  final LocationAccess location;
  final PlacesRepository places;

  Future<Result<PickupSpot?>> call({required String languageCode}) async {
    final point = await location.currentPosition();
    if (point == null) {
      return const Ok(null);
    }

    final address = await places.addressAt(point, languageCode: languageCode);

    return Ok(PickupSpot(point: point, address: address.fold((name) => name, (_) => null)));
  }
}
