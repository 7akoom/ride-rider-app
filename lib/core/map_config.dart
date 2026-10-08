import 'models/geo_point.dart';

/// The map style, served by the platform's own map server
/// (scripts/deploy/prepare-tiles.sh in ride-platform). Four styles exist:
/// light-ar, light-en, dark-ar, dark-en.
const String kMapStyleUrl = 'https://ride-tiles.lenda-agency.com/styles/light-ar.json';

/// Where the map opens when the phone's position is not known.
const GeoPoint kErbilCenter = GeoPoint(36.1911, 44.0092);
