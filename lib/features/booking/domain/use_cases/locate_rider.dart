import '../../../../core/error/result.dart';
import '../entities/spot.dart';
import 'find_pickup.dart';
import 'turn_on_location.dart';

/// "Use my location" for the pickup: where the rider is, asking for location first
/// when it is not allowed or off. Null when it still cannot be found.
final class LocateRider {
  const LocateRider({required this.find, required this.turnOn});

  final FindPickup find;
  final TurnOnLocation turnOn;

  Future<Spot?> call({required String languageCode}) async {
    final first = await _find(languageCode);
    if (first != null) {
      return first;
    }

    await turnOn();

    return _find(languageCode);
  }

  Future<Spot?> _find(String languageCode) async {
    final result = await find(languageCode: languageCode);

    return result is Ok<Spot?> ? result.value : null;
  }
}
