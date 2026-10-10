import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/error/failure.dart';
import 'package:rider_app/core/error/result.dart';
import 'package:rider_app/core/location/location_access.dart';
import 'package:rider_app/features/booking/domain/entities/day_part.dart';
import 'package:rider_app/features/booking/domain/entities/saved_place.dart';
import 'package:rider_app/features/booking/domain/entities/spot.dart';
import 'package:rider_app/features/booking/domain/use_cases/find_pickup.dart';
import 'package:rider_app/features/booking/domain/use_cases/load_shortcuts.dart';
import 'package:rider_app/features/booking/domain/use_cases/turn_on_location.dart';

import '../fakes.dart';

void main() {
  test('greetings follow the time of day', () {
    expect(DayPart.of(DateTime(2026, 1, 1, 8)), DayPart.morning);
    expect(DayPart.of(DateTime(2026, 1, 1, 13)), DayPart.afternoon);
    expect(DayPart.of(DateTime(2026, 1, 1, 21)), DayPart.evening);
    expect(DayPart.of(DateTime(2026, 1, 1, 2)), DayPart.evening);
  });

  group('FindPickup', () {
    Spot? spot(Result<Spot?> result) => result.fold((s) => s, (_) => null);

    test('no position: no pickup, and no failure', () async {
      final result = await FindPickup(location: FakeLocation(), places: FakePlaces())
          .call(languageCode: 'ar');

      expect(result, isA<Ok<Spot?>>());
      expect(spot(result), isNull);
    });

    test('a position with its address', () async {
      final result = await FindPickup(
        location: FakeLocation(current: LocationAccessStatus.granted),
        places: FakePlaces(),
      ).call(languageCode: 'ar');

      expect(spot(result)?.title, 'Gulan Street');
    });

    test('no address (offline) still gives the pickup', () async {
      final result = await FindPickup(
        location: FakeLocation(current: LocationAccessStatus.granted),
        places: FakePlaces(failure: const NetworkFailure()),
      ).call(languageCode: 'ar');

      expect(spot(result), isNotNull);
      expect(spot(result)?.title, isNull);
    });
  });

  test('shortcuts: home, work, then the others, at most four', () async {
    final saved = FakeSavedPlaces(Ok([
      savedPlace(SavedPlaceKind.other, label: 'Gym'),
      savedPlace(SavedPlaceKind.work),
      savedPlace(SavedPlaceKind.other, label: 'Mum'),
      savedPlace(SavedPlaceKind.home),
      savedPlace(SavedPlaceKind.other, label: 'Uni'),
    ]));

    final result = await LoadShortcuts(saved).call();
    final kinds = result.fold((places) => places.map((p) => p.kind).toList(), (_) => null);

    expect(kinds, [
      SavedPlaceKind.home,
      SavedPlaceKind.work,
      SavedPlaceKind.other,
      SavedPlaceKind.other,
    ]);
  });

  group('TurnOnLocation', () {
    test('asks while the system can still ask', () async {
      final location = FakeLocation();
      await TurnOnLocation(location).call();

      expect(location.prompts, 1);
    });

    test('opens the settings when refused for good or switched off', () async {
      for (final status in [
        LocationAccessStatus.deniedForever,
        LocationAccessStatus.serviceOff,
      ]) {
        final location = FakeLocation(current: status);
        await TurnOnLocation(location).call();

        expect(location.prompts, 0);
        expect(location.settingsOpened, 1);
      }
    });
  });
}
