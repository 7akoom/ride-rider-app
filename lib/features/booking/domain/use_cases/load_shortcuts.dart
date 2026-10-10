import '../../../../core/error/result.dart';
import '../entities/saved_place.dart';
import '../repositories/saved_places_repository.dart';

/// The saved addresses shown on the home screen: home, work, then the others, at most
/// [limit].
final class LoadShortcuts {
  const LoadShortcuts(this.places);

  final SavedPlacesRepository places;

  static const int limit = 4;

  Future<Result<List<SavedPlace>>> call() async {
    return switch (await places.list()) {
      Ok(:final value) => Ok([
          ...value.where((p) => p.kind == SavedPlaceKind.home),
          ...value.where((p) => p.kind == SavedPlaceKind.work),
          ...value.where((p) => p.kind == SavedPlaceKind.other),
        ].take(limit).toList()),
      Err(:final failure) => Err(failure),
    };
  }
}
