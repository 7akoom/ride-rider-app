import 'package:geolocator/geolocator.dart';

import '../error/error_reporter.dart';
import 'geo_point.dart';
import 'location_access.dart';

/// [LocationAccess] on Android and iOS through the geolocator plugin. A plugin error
/// counts as "not allowed" or "no position": the app carries on without it.
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

  @override
  Future<void> openLocationSettings() async {
    try {
      await Geolocator.openLocationSettings();
    } catch (error, stack) {
      ErrorReporter.report(error, stack);
    }
  }

  @override
  Future<GeoPoint?> currentPosition() async {
    if (await status() != LocationAccessStatus.granted) {
      return null;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: _positionTimeout,
        ),
      );

      return GeoPoint(position.latitude, position.longitude);
    } catch (error, stack) {
      // No fix in time (indoors, GPS warming up): the last known one, if any.
      ErrorReporter.report(error, stack);

      return _lastKnown();
    }
  }

  static const Duration _positionTimeout = Duration(seconds: 10);

  static Future<GeoPoint?> _lastKnown() async {
    try {
      final last = await Geolocator.getLastKnownPosition();

      return last == null ? null : GeoPoint(last.latitude, last.longitude);
    } catch (error, stack) {
      ErrorReporter.report(error, stack);

      return null;
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
