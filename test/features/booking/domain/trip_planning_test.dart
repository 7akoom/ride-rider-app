import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/error/failure.dart';
import 'package:rider_app/core/error/result.dart';
import 'package:rider_app/core/format/distance_format.dart';
import 'package:rider_app/core/l10n/app_locales.dart';
import 'package:rider_app/core/l10n/l10n.dart';
import 'package:rider_app/core/location/distance.dart';
import 'package:rider_app/core/location/geo_point.dart';
import 'package:rider_app/features/booking/domain/entities/route_estimate.dart';
import 'package:rider_app/features/booking/domain/entities/saved_place.dart';
import 'package:rider_app/features/booking/domain/entities/spot.dart';
import 'package:rider_app/features/booking/domain/entities/trip_draft.dart';
import 'package:rider_app/features/booking/domain/use_cases/estimate_route.dart';
import 'package:rider_app/features/booking/domain/use_cases/load_suggestions.dart';
import 'package:rider_app/features/booking/domain/use_cases/name_point.dart';
import 'package:rider_app/features/booking/domain/use_cases/search_places.dart';

import '../fakes.dart';

void main() {
  group('TripDraft', () {
    final a = spotNamed('A');
    final b = spotNamed('B');
    final c = spotNamed('C');

    test('two stops at most, kept in order', () {
      final draft = const TripDraft().withStop(0, a).withStop(1, b).withStop(2, c);

      expect(draft.stops.map((s) => s.title), ['A', 'B']);
      expect(draft.canAddStop, isFalse);
      expect(draft.withoutStop(0).stops.single.title, 'B');
    });

    test('complete with both ends; points run pickup, stops, destination', () {
      const pickup = Spot(point: GeoPoint(1, 1), kind: SpotKind.currentLocation);
      const end = Spot(point: GeoPoint(3, 3), kind: SpotKind.other);
      const draft = TripDraft(stops: [Spot(point: GeoPoint(2, 2), kind: SpotKind.other)]);

      expect(draft.isComplete, isFalse);
      expect(
        draft.withPickup(pickup).withDestination(end).points,
        const [GeoPoint(1, 1), GeoPoint(2, 2), GeoPoint(3, 3)],
      );
    });
  });

  test('search waits for two letters', () async {
    final places = FakePlaces(found: [spotNamed('Family Mall')]);

    final short = await SearchPlaces(places).call(' f ', languageCode: 'ar');
    final long = await SearchPlaces(places).call('fa', languageCode: 'ar');

    expect(short.fold((s) => s, (_) => null), isEmpty);
    expect(long.fold((s) => s.single.title, (_) => null), 'Family Mall');
    expect(places.queries, ['fa']);
  });

  test('suggestions: saved places stay when popular ones fail', () async {
    final suggestions = await LoadSuggestions(
      saved: FakeSavedPlaces(Ok([savedPlace(SavedPlaceKind.home)])),
      places: FakePlaces(failure: const NetworkFailure()),
    ).call(languageCode: 'ar');

    expect(suggestions.saved.single.kind, SpotKind.home);
    expect(suggestions.featured, isEmpty);
  });

  test('a picked point without a name is still a point', () async {
    final spot = await NamePoint(FakePlaces(failure: const NetworkFailure()))
        .call(const GeoPoint(36.2, 44.0), languageCode: 'ar');

    expect(spot.kind, SpotKind.pinned);
    expect(spot.title, isNull);
  });

  test('no route without both ends; no road is told apart', () async {
    final none = await EstimateRoute(FakeRoutes()).call(const TripDraft());

    expect(none, isA<Err<RouteEstimate>>());
    expect(isNoRoad(const NotFoundFailure()), isTrue);
    expect(isNoRoad(const NetworkFailure()), isFalse);
  });

  test('distances: meters, then kilometers', () {
    final l10n = lookupAppLocalizations(AppLocales.english);

    expect(formatDistance(l10n, 347), contains('350'));
    expect(formatDistance(l10n, 2140), contains('2.1'));
    expect(metersBetween(const GeoPoint(36.19, 44.01), const GeoPoint(36.20, 44.01)),
        closeTo(1112, 5));
  });
}
