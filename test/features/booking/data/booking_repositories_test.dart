import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/error/failure.dart';
import 'package:rider_app/core/location/geo_point.dart';
import 'package:rider_app/core/network/api_client.dart';
import 'package:rider_app/core/network/api_exception.dart';
import 'package:rider_app/features/booking/data/booking_api.dart';
import 'package:rider_app/features/booking/data/places_repository_impl.dart';
import 'package:rider_app/features/booking/data/routes_repository_impl.dart';
import 'package:rider_app/features/booking/data/saved_places_repository_impl.dart';
import 'package:rider_app/features/booking/domain/entities/saved_place.dart';
import 'package:rider_app/features/booking/domain/entities/spot.dart';

class _Api implements BookingApi {
  JsonMap addresses = {};
  JsonMap place = {};
  JsonMap found = {};
  JsonMap routed = {};
  Object? error;
  List<GeoPoint>? routedThrough;

  @override
  Future<JsonMap> search(String query, GeoPoint? near, String languageCode) async =>
      error == null ? found : throw error!;

  @override
  Future<JsonMap> curated(GeoPoint? near) async => error == null ? found : throw error!;

  @override
  Future<JsonMap> route(List<GeoPoint> points) async {
    routedThrough = points;

    return error == null ? routed : throw error!;
  }

  @override
  Future<JsonMap> savedAddresses(String riderId) async =>
      error == null ? addresses : throw error!;

  @override
  Future<JsonMap> reverse(GeoPoint point, String languageCode) async =>
      error == null ? place : throw error!;
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({'rider_id': 'r1'}));

  test('saved addresses are read with their kind', () async {
    final api = _Api()
      ..addresses = {
        'addresses': [
          {
            'id': 'a1',
            'kind': 'SAVED_ADDRESS_KIND_HOME',
            'address': 'Gulan',
            'coordinates': {'latitude': 36.2, 'longitude': 44.0},
          },
          {'id': 'a2', 'kind': 'SAVED_ADDRESS_KIND_OTHER', 'label': 'Gym'},
        ],
      };

    final result = await SavedPlacesRepositoryImpl(api).list();
    final places = result.fold((p) => p, (_) => <SavedPlace>[]);

    expect(places.map((p) => p.kind), [SavedPlaceKind.home, SavedPlaceKind.other]);
    expect(places.last.label, 'Gym');
  });

  test('no rider id is a refused session, never an exception', () async {
    FlutterSecureStorage.setMockInitialValues({});

    final result = await SavedPlacesRepositoryImpl(_Api()).list();

    expect(result.fold((_) => null, (f) => f), isA<SessionExpiredFailure>());
  });

  test('the address of a point: its name, or nothing there', () async {
    final api = _Api()..place = {'place': {'name': 'Family Mall'}};
    final repo = PlacesRepositoryImpl(api);

    final named = await repo.addressAt(const GeoPoint(36.2, 44.0), languageCode: 'en');
    expect(named.fold((a) => a, (_) => 'failed'), 'Family Mall');

    api.error = const ApiException(statusCode: 404, code: 5, message: 'nothing');
    final nothing = await repo.addressAt(const GeoPoint(36.2, 44.0), languageCode: 'en');
    expect(nothing.fold((a) => a, (_) => 'failed'), isNull);
  });

  test('search results: name, the rest of the address, the kind', () async {
    final api = _Api()
      ..found = {
        'places': [
          {
            'name': 'Family Mall',
            'displayName': 'Family Mall, 100m Street, Erbil, Iraq',
            'category': 'mall',
            'coordinates': {'latitude': 36.2, 'longitude': 44.0},
          },
          {'name': 'No position'},
        ],
      };

    final result = await PlacesRepositoryImpl(api).search('fam', languageCode: 'en');
    final spots = result.fold((s) => s, (_) => <Spot>[]);

    expect(spots, hasLength(1));
    expect(spots.single.title, 'Family Mall');
    expect(spots.single.detail, '100m Street, Erbil');
    expect(spots.single.kind, SpotKind.mall);
  });

  test('curated places use the name in the rider\'s language', () async {
    final api = _Api()
      ..found = {
        'places': [
          {
            'name': 'Erbil Airport',
            'names': {'en': 'Erbil International Airport'},
            'category': 'PLACE_CATEGORY_AIRPORT',
            'coordinates': {'latitude': 36.23, 'longitude': 43.96},
          },
        ],
      };

    final result = await PlacesRepositoryImpl(api).featured(languageCode: 'en');
    final spot = result.fold((s) => s.single, (_) => null)!;

    expect(spot.title, 'Erbil International Airport');
    expect(spot.kind, SpotKind.airport);
  });

  test('a route goes through the stops and decodes the line', () async {
    final api = _Api()
      ..routed = {'distanceMeters': 5300, 'durationSeconds': 720, 'polyline': '_p~iF~ps|U_ulLnnqC'};
    const points = [GeoPoint(36.1, 44.0), GeoPoint(36.15, 44.02), GeoPoint(36.2, 44.05)];

    final result = await RoutesRepositoryImpl(api).route(points);
    final route = result.fold((r) => r, (_) => null)!;

    expect(api.routedThrough, points);
    expect(route.duration, const Duration(minutes: 12));
    expect(route.path, hasLength(2));
  });
}
