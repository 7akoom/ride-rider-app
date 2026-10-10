import '../../../../core/location/geo_point.dart';
import '../entities/spot.dart';
import '../repositories/places_repository.dart';
import '../repositories/saved_places_repository.dart';
import 'spot_of_saved.dart';

/// What the search shows before anything is typed.
final class Suggestions {
  const Suggestions({this.saved = const [], this.featured = const []});

  final List<Spot> saved;
  final List<Spot> featured;

  bool get isEmpty => saved.isEmpty && featured.isEmpty;
}

/// The rider's saved addresses and the popular places nearby. Each list loads on its
/// own: one failing leaves the other.
final class LoadSuggestions {
  const LoadSuggestions({required this.saved, required this.places});

  final SavedPlacesRepository saved;
  final PlacesRepository places;

  static const int featuredLimit = 6;

  Future<Suggestions> call({GeoPoint? near, required String languageCode}) async {
    // Both asked at once; each answer is used on its own.
    final savedAnswer = saved.list();
    final featuredAnswer = places.featured(near: near, languageCode: languageCode);

    final savedPlaces = (await savedAnswer).fold(
      (list) => [for (final place in list) spotOfSaved(place)],
      (_) => const <Spot>[],
    );
    final featured = (await featuredAnswer).fold(
      (list) => list.take(featuredLimit).toList(),
      (_) => const <Spot>[],
    );

    return Suggestions(saved: savedPlaces, featured: featured);
  }
}
