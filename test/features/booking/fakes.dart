import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rider_app/core/error/failure.dart';
import 'package:rider_app/core/error/result.dart';
import 'package:rider_app/core/location/geo_point.dart';
import 'package:rider_app/core/location/location_providers.dart';
import 'package:rider_app/core/rider/rider_providers.dart';
import 'package:rider_app/features/booking/booking_providers.dart';
import 'package:rider_app/features/booking/trip_end_providers.dart';
import 'package:rider_app/features/booking/domain/entities/route_estimate.dart';
import 'package:rider_app/features/booking/domain/entities/saved_place.dart';
import 'package:rider_app/features/booking/domain/entities/spot.dart';
import 'package:rider_app/features/booking/domain/repositories/places_repository.dart';
import 'package:rider_app/features/booking/domain/repositories/routes_repository.dart';
import 'package:rider_app/features/booking/domain/repositories/saved_places_repository.dart';

import '../../helpers/fake_location.dart';
import '../../helpers/fake_rider.dart';
import 'fake_captains.dart';
import 'fake_rides.dart';
import 'fake_safety.dart';
import 'fake_trip_end.dart';
import 'fake_schedules.dart';

export '../../helpers/fake_location.dart';
export '../../helpers/fake_rider.dart';
export 'fake_captains.dart';
export 'fake_rides.dart';
export 'fake_safety.dart';
export 'fake_trip_end.dart';
export 'fake_schedules.dart';

class FakeSavedPlaces implements SavedPlacesRepository {
  FakeSavedPlaces([this.result = const Ok(<SavedPlace>[])]);

  Result<List<SavedPlace>> result;

  @override
  Future<Result<List<SavedPlace>>> list() async => result;
}

class FakePlaces implements PlacesRepository {
  FakePlaces({
    this.address = 'Gulan Street',
    this.failure,
    this.found = const [],
    this.popular = const [],
  });

  String? address;

  /// When set, every call fails with it.
  Failure? failure;
  List<Spot> found;
  List<Spot> popular;
  final List<String> queries = [];

  Result<T> _answer<T>(T value) {
    final f = failure;

    return f == null ? Ok(value) : Err(f);
  }

  @override
  Future<Result<String?>> addressAt(GeoPoint point, {required String languageCode}) async =>
      _answer(address);

  @override
  Future<Result<List<Spot>>> search(
    String query, {
    GeoPoint? near,
    required String languageCode,
  }) async {
    queries.add(query);

    return _answer(found);
  }

  @override
  Future<Result<List<Spot>>> featured({GeoPoint? near, required String languageCode}) async =>
      _answer(popular);
}

class FakeRoutes implements RoutesRepository {
  FakeRoutes({this.failure});

  Failure? failure;

  @override
  Future<Result<RouteEstimate>> route(List<GeoPoint> points) async {
    final f = failure;

    return f == null
        ? const Ok(RouteEstimate(
            distanceMeters: 5300,
            duration: Duration(minutes: 12),
            path: [GeoPoint(36.19, 44.01), GeoPoint(36.2, 44.02)],
          ))
        : Err(f);
  }
}

Spot spotNamed(String title, {SpotKind kind = SpotKind.other}) =>
    Spot(point: const GeoPoint(36.21, 44.02), kind: kind, title: title);

SavedPlace savedPlace(SavedPlaceKind kind, {String label = ''}) => SavedPlace(
      id: kind.name + label,
      kind: kind,
      label: label,
      address: 'Somewhere',
      point: const GeoPoint(36.2, 44.0),
    );

/// The booking repositories replaced by fakes, for screen tests.
List<Override> bookingFakes({
  FakeLocation? location,
  FakeAccounts? accounts,
  FakeSavedPlaces? saved,
  FakePlaces? places,
  FakeRoutes? routes,
  FakeRides? rides,
  FakeSchedules? schedules,
  FakeCaptains? captains,
  FakeSafety? safety,
  FakeTripEnd? tripEnd,
}) =>
    [
      routesRepositoryProvider.overrideWithValue(routes ?? FakeRoutes()),
      locationAccessProvider.overrideWithValue(location ?? FakeLocation()),
      riderAccountRepositoryProvider.overrideWithValue(
        accounts ?? FakeAccounts(const Ok(someone)),
      ),
      savedPlacesRepositoryProvider.overrideWithValue(saved ?? FakeSavedPlaces()),
      placesRepositoryProvider.overrideWithValue(places ?? FakePlaces()),
      ridesRepositoryProvider.overrideWithValue(rides ?? FakeRides()),
      schedulesRepositoryProvider.overrideWithValue(schedules ?? FakeSchedules()),
      captainRepositoryProvider.overrideWithValue(captains ?? FakeCaptains()),
      safetyRepositoryProvider.overrideWithValue(safety ?? FakeSafety()),
      tripEndRepositoryProvider.overrideWithValue(tripEnd ?? FakeTripEnd()),
    ];
