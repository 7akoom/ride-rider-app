import '../../../../core/location/location_access.dart';

/// "Turn on" in the home screen's location notice: whatever stands in the way. The
/// system prompt when it can still ask, otherwise the right settings page.
final class TurnOnLocation {
  const TurnOnLocation(this.location);

  final LocationAccess location;

  Future<void> call() async {
    switch (await location.status()) {
      case LocationAccessStatus.denied:
        await location.request();
      case LocationAccessStatus.deniedForever:
        await location.openSettings();
      case LocationAccessStatus.serviceOff:
        await location.openLocationSettings();
      case LocationAccessStatus.granted:
        break;
    }
  }
}
