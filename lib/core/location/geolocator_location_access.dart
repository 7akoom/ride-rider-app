import 'package:geolocator/geolocator.dart';

import '../error/error_reporter.dart';
import 'location_access.dart';

/// [LocationAccess] on Android and iOS through the geolocator plugin. A plugin error
/// counts as "not allowed": the app carries on without the location.
final class GeolocatorLocationAccess implements LocationAccess {
  const GeolocatorLocationAccess();

  @override
  Future<LocationAccessStatus> status() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return LocationAccessStatus.serviceOff;
      }

      return _statusOf(await Geolocator.checkPermission());
    } catch (error, stack) {
      ErrorReporter.report(error, stack);

      return LocationAccessStatus.denied;
    }
  }

  @override
  Future<LocationAccessStatus> request() async {
    try {
      return _statusOf(await Geolocator.requestPermission());
    } catch (error, stack) {
      ErrorReporter.report(error, stack);

      return LocationAccessStatus.denied;
    }
  }

  @override
  Future<void> openSettings() async {
    try {
      await Geolocator.openAppSettings();
    } catch (error, stack) {
      ErrorReporter.report(error, stack);
    }
  }

  static LocationAccessStatus _statusOf(LocationPermission permission) =>
      switch (permission) {
        LocationPermission.always ||
        LocationPermission.whileInUse =>
          LocationAccessStatus.granted,
        LocationPermission.deniedForever => LocationAccessStatus.deniedForever,
        LocationPermission.denied ||
        LocationPermission.unableToDetermine =>
          LocationAccessStatus.denied,
      };
}
