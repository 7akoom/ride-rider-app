import '../entities/saved_place.dart';
import '../entities/spot.dart';

/// A saved address as a spot of the trip. Home and work keep no title of their own:
/// the screen names them in the rider's language.
Spot spotOfSaved(SavedPlace place) => Spot(
      point: place.point,
      kind: switch (place.kind) {
        SavedPlaceKind.home => SpotKind.home,
        SavedPlaceKind.work => SpotKind.work,
        SavedPlaceKind.other => SpotKind.saved,
      },
      title: place.kind == SavedPlaceKind.other ? place.label : null,
      detail: place.address.isEmpty ? null : place.address,
      savedPlaceId: place.id,
    );
