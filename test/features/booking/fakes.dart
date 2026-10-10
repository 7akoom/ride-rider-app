import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rider_app/core/error/failure.dart';
import 'package:rider_app/core/error/result.dart';
import 'package:rider_app/core/location/geo_point.dart';
import 'package:rider_app/core/location/location_providers.dart';
import 'package:rider_app/core/rider/rider_providers.dart';
import 'package:rider_app/features/booking/booking_providers.dart';
import 'package:rider_app/features/booking/domain/entities/saved_place.dart';
import 'package:rider_app/features/booking/domain/repositories/places_repository.dart';
import 'package:rider_app/features/booking/domain/repositories/saved_places_repository.dart';

import '../../helpers/fake_location.dart';
import '../../helpers/fake_rider.dart';

export '../../helpers/fake_location.dart';
export '../../helpers/fake_rider.dart';

class FakeSavedPlaces implements SavedPlacesRepository {
  FakeSavedPlaces([this.result = const Ok(<SavedPlace>[])]);

  Result<List<SavedPlace>> result;

  @override
  Future<Result<List<SavedPlace>>> list() async => result;
}

class FakePlaces implements PlacesRepository {
  FakePlaces({this.address = 'Gulan Street', this.failure});

  String? address;
  Failure? failure;

  @override
  Future<Result<String?>> addressAt(GeoPoint point, {required String languageCode}) async {
    final f = failure;

    return f == null ? Ok(address) : Err(f);
  }
}

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
}) =>
    [
      locationAccessProvider.overrideWithValue(location ?? FakeLocation()),
      riderAccountRepositoryProvider.overrideWithValue(
        accounts ?? FakeAccounts(const Ok(someone)),
      ),
      savedPlacesRepositoryProvider.overrideWithValue(saved ?? FakeSavedPlaces()),
      placesRepositoryProvider.overrideWithValue(places ?? FakePlaces()),
    ];
