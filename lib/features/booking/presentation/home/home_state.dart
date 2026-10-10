import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/location/location_access.dart';
import '../../../../core/location/location_providers.dart';
import '../../../../core/rider/rider_providers.dart';
import '../../../../state/locale_provider.dart';
import '../../booking_providers.dart';
import '../../domain/entities/saved_place.dart';
import '../../domain/entities/spot.dart';

// What the home screen shows. Each part loads on its own, so a slow or failed part
// never holds up the others. Re-read when the app comes back to the front.

/// The rider's first name for the greeting; null when it is not known.
final riderFirstNameProvider = FutureProvider.autoDispose<String?>((ref) async {
  final result = await ref.watch(riderAccountRepositoryProvider).findMine();

  return result.fold(
    (account) {
      final name = account?.displayName.trim() ?? '';

      return name.isEmpty ? null : name.split(' ').first;
    },
    (_) => null,
  );
});

final locationStatusProvider = FutureProvider.autoDispose<LocationAccessStatus>(
  (ref) => ref.watch(locationAccessProvider).status(),
);

/// Where the rider is; null without a position.
final pickupProvider = FutureProvider.autoDispose<Spot?>((ref) async {
  final language = ref.watch(localeProvider).languageCode;
  final result = await ref.watch(findPickupProvider).call(languageCode: language);

  return result.fold((spot) => spot, (_) => null);
});

/// Saved places for the shortcuts; empty when there are none or they cannot be loaded
/// (the rest of the screen works without them).
final shortcutsProvider = FutureProvider.autoDispose<List<SavedPlace>>((ref) async {
  final result = await ref.watch(loadShortcutsProvider).call();

  return result.fold((places) => places, (_) => const <SavedPlace>[]);
});

/// Reads everything again (back from the settings, back to the app).
void refreshHome(WidgetRef ref) {
  ref
    ..invalidate(locationStatusProvider)
    ..invalidate(pickupProvider)
    ..invalidate(shortcutsProvider);
}
