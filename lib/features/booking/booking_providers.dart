import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/location/location_providers.dart';
import '../../core/network/api_client_provider.dart';
import 'data/booking_api.dart';
import 'data/places_repository_impl.dart';
import 'data/saved_places_repository_impl.dart';
import 'domain/repositories/places_repository.dart';
import 'domain/repositories/saved_places_repository.dart';
import 'domain/use_cases/find_pickup.dart';
import 'domain/use_cases/load_shortcuts.dart';
import 'domain/use_cases/turn_on_location.dart';

// The feature's wiring: the one file that knows both the data classes and the domain
// interfaces. Tests override the repositories, locationAccessProvider and
// riderAccountRepositoryProvider.

final bookingApiProvider = Provider<BookingApi>(
  (ref) => BookingApi(ref.watch(apiClientProvider)),
);

final savedPlacesRepositoryProvider = Provider<SavedPlacesRepository>(
  (ref) => SavedPlacesRepositoryImpl(ref.watch(bookingApiProvider)),
);

final placesRepositoryProvider = Provider<PlacesRepository>(
  (ref) => PlacesRepositoryImpl(ref.watch(bookingApiProvider)),
);

final findPickupProvider = Provider<FindPickup>(
  (ref) => FindPickup(
    location: ref.watch(locationAccessProvider),
    places: ref.watch(placesRepositoryProvider),
  ),
);

final loadShortcutsProvider = Provider<LoadShortcuts>(
  (ref) => LoadShortcuts(ref.watch(savedPlacesRepositoryProvider)),
);

final turnOnLocationProvider = Provider<TurnOnLocation>(
  (ref) => TurnOnLocation(ref.watch(locationAccessProvider)),
);
