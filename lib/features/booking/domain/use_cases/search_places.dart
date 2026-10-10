import '../../../../core/error/result.dart';
import '../../../../core/location/geo_point.dart';
import '../entities/spot.dart';
import '../repositories/places_repository.dart';

/// Places by what the rider typed. Under [minLength] characters there is nothing to
/// look for yet (the backend refuses shorter queries).
final class SearchPlaces {
  const SearchPlaces(this.places);

  final PlacesRepository places;

  static const int minLength = 2;

  Future<Result<List<Spot>>> call(
    String typed, {
    GeoPoint? near,
    required String languageCode,
  }) async {
    final query = typed.trim();

    if (query.runes.length < minLength) {
      return const Ok(<Spot>[]);
    }

    return places.search(query, near: near, languageCode: languageCode);
  }
}
