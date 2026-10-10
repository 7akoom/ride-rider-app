import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/error/failure.dart';
import 'package:rider_app/core/location/geo_point.dart';
import 'package:rider_app/core/network/api_client.dart';
import 'package:rider_app/core/network/api_exception.dart';
import 'package:rider_app/features/booking/data/booking_api.dart';
import 'package:rider_app/features/booking/data/places_repository_impl.dart';
import 'package:rider_app/features/booking/data/saved_places_repository_impl.dart';
import 'package:rider_app/features/booking/domain/entities/saved_place.dart';

class _Api implements BookingApi {
  JsonMap addresses = {};
  JsonMap place = {};
  Object? error;

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
}
