import 'package:rider_app/core/location/geo_point.dart';
import 'package:rider_app/core/location/location_access.dart';

class FakeLocation implements LocationAccess {
  FakeLocation({
    this.current = LocationAccessStatus.denied,
    this.answer = LocationAccessStatus.granted,
  });

  LocationAccessStatus current;

  /// What the system prompt answers.
  LocationAccessStatus answer;
  int prompts = 0;
  int settingsOpened = 0;

  @override
  Future<LocationAccessStatus> status() async => current;

  @override
  Future<LocationAccessStatus> request() async {
    prompts++;
    current = answer;

    return answer;
  }

  @override
  Future<void> openSettings() async => settingsOpened++;

  @override
  Future<void> openLocationSettings() async => settingsOpened++;

  /// Where the fake phone is; only given while [current] is granted.
  GeoPoint position = const GeoPoint(36.19, 44.01);

  @override
  Future<GeoPoint?> currentPosition() async =>
      current == LocationAccessStatus.granted ? position : null;
}
