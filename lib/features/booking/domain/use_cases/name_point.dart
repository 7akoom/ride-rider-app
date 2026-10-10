import '../../../../core/location/geo_point.dart';
import '../entities/spot.dart';
import '../repositories/places_repository.dart';

/// A point picked on the map, named by what is there. Not knowing the name (nothing
/// there, no connection) still gives the point: it is what the trip needs.
final class NamePoint {
  const NamePoint(this.places);

  final PlacesRepository places;

  Future<Spot> call(GeoPoint point, {required String languageCode}) async {
    final name = await places.addressAt(point, languageCode: languageCode);

    return Spot(
      point: point,
      kind: SpotKind.pinned,
      title: name.fold((value) => value, (_) => null),
    );
  }
}
