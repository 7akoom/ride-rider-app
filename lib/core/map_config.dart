import 'config/app_env.dart';
import 'models/geo_point.dart';

/// Legacy: the light Arabic map style, for the screens not migrated yet. New code uses
/// mapStyleUrl() in lib/design/map, which follows the mode and the language.
const String kMapStyleUrl = '${AppEnv.mapTilesUrl}/styles/light-ar.json';

/// Where the map opens when the phone's position is not known.
const GeoPoint kErbilCenter = GeoPoint(36.1911, 44.0092);
