import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'geolocator_location_access.dart';
import 'location_access.dart';

/// The location permission, for every feature. Tests override it with a fake.
final locationAccessProvider = Provider<LocationAccess>(
  (ref) => const GeolocatorLocationAccess(),
);
