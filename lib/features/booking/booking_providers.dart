import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/location/location_providers.dart';
import '../../core/network/api_client_provider.dart';
import 'data/booking_api.dart';
import 'data/places_repository_impl.dart';
import 'data/rides_api.dart';
import 'data/rides_repository_impl.dart';
import 'data/schedules_repository_impl.dart';
import 'data/routes_repository_impl.dart';
import 'data/saved_places_repository_impl.dart';
import 'domain/repositories/places_repository.dart';
import 'domain/repositories/rides_repository.dart';
import 'domain/repositories/routes_repository.dart';
import 'domain/repositories/saved_places_repository.dart';
import 'domain/repositories/schedules_repository.dart';
import 'domain/use_cases/book_ride.dart';
import 'domain/use_cases/estimate_route.dart';
import 'domain/use_cases/find_pickup.dart';
import 'domain/use_cases/follow_ride.dart';
import 'domain/use_cases/load_shortcuts.dart';
import 'domain/use_cases/load_suggestions.dart';
import 'domain/use_cases/load_wallet_balance.dart';
import 'domain/use_cases/locate_rider.dart';
import 'domain/use_cases/name_point.dart';
import 'domain/use_cases/order_ride.dart';
import 'domain/use_cases/quote_ride.dart';
import 'domain/use_cases/retry_ride.dart';
import 'domain/use_cases/search_places.dart';
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

final routesRepositoryProvider = Provider<RoutesRepository>(
  (ref) => RoutesRepositoryImpl(ref.watch(bookingApiProvider)),
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

final searchPlacesProvider = Provider<SearchPlaces>(
  (ref) => SearchPlaces(ref.watch(placesRepositoryProvider)),
);

final loadSuggestionsProvider = Provider<LoadSuggestions>(
  (ref) => LoadSuggestions(
    saved: ref.watch(savedPlacesRepositoryProvider),
    places: ref.watch(placesRepositoryProvider),
  ),
);

final estimateRouteProvider = Provider<EstimateRoute>(
  (ref) => EstimateRoute(ref.watch(routesRepositoryProvider)),
);

final namePointProvider = Provider<NamePoint>(
  (ref) => NamePoint(ref.watch(placesRepositoryProvider)),
);

final ridesApiProvider = Provider<RidesApi>((ref) => RidesApi(ref.watch(apiClientProvider)));

final ridesRepositoryProvider = Provider<RidesRepository>(
  (ref) => RidesRepositoryImpl(ref.watch(ridesApiProvider)),
);

final schedulesRepositoryProvider = Provider<SchedulesRepository>(
  (ref) => SchedulesRepositoryImpl(ref.watch(ridesApiProvider)),
);

final quoteRideProvider = Provider<QuoteRide>(
  (ref) => QuoteRide(ref.watch(ridesRepositoryProvider)),
);

final orderRideProvider = Provider<OrderRide>(
  (ref) => OrderRide(ref.watch(ridesRepositoryProvider)),
);

final loadWalletBalanceProvider = Provider<LoadWalletBalance>(
  (ref) => LoadWalletBalance(ref.watch(ridesRepositoryProvider)),
);

final loadRideProvider = Provider<LoadRide>(
  (ref) => LoadRide(ref.watch(ridesRepositoryProvider)),
);

final findActiveRideProvider = Provider<FindActiveRide>(
  (ref) => FindActiveRide(ref.watch(ridesRepositoryProvider)),
);

final cancelRideProvider = Provider<CancelRide>(
  (ref) => CancelRide(ref.watch(ridesRepositoryProvider)),
);

final retryRideProvider = Provider<RetryRide>(
  (ref) => RetryRide(quote: ref.watch(quoteRideProvider), order: ref.watch(orderRideProvider)),
);

final locateRiderProvider = Provider<LocateRider>(
  (ref) => LocateRider(find: ref.watch(findPickupProvider), turnOn: ref.watch(turnOnLocationProvider)),
);

final bookRideProvider = Provider<BookRide>(
  (ref) => BookRide(ref.watch(schedulesRepositoryProvider)),
);

final cancelBookingProvider = Provider<CancelBooking>(
  (ref) => CancelBooking(ref.watch(schedulesRepositoryProvider)),
);
