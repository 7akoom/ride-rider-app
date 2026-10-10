import '../../../../core/error/result.dart';
import '../entities/saved_place.dart';

/// The signed-in rider's saved addresses.
abstract interface class SavedPlacesRepository {
  /// Home first, then work, then the others by label (the backend's order).
  Future<Result<List<SavedPlace>>> list();
}
