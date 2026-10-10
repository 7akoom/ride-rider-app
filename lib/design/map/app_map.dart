import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../core/config/app_env.dart';
import '../../core/error/error_reporter.dart';
import '../../core/location/geo_point.dart';
import '../design_context.dart';
import 'map_style.dart';

/// Moves the map. Screens use this, never the plugin's controller.
class AppMapController {
  AppMapController(this._map);

  final MapLibreMapController _map;

  /// The point in the middle of the map, when it is known.
  GeoPoint? get center {
    final target = _map.cameraPosition?.target;

    return target == null ? null : GeoPoint(target.latitude, target.longitude);
  }

  Future<void> moveTo(GeoPoint point, {double zoom = AppMap.streetZoom}) async {
    try {
      await _map.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(point.latitude, point.longitude), zoom),
      );
    } catch (error, stack) {
      // The map was closed or is not ready: moving it can wait for the next time.
      ErrorReporter.report(error, stack);
    }
  }
}

/// The platform's own map (MapLibre with the copy's tile server), in the style of the
/// current mode and language. It opens on [center], or on the copy's city.
class AppMap extends StatefulWidget {
  const AppMap({
    super.key,
    this.center,
    this.zoom = cityZoom,
    this.showMyLocation = false,
    this.onCreated,
    this.onSettled,
  });

  final GeoPoint? center;
  final double zoom;

  /// The blue dot. Only when location is allowed.
  final bool showMyLocation;
  final ValueChanged<AppMapController>? onCreated;

  /// The middle of the map each time the rider stops moving it (picking a point).
  final ValueChanged<GeoPoint>? onSettled;

  static const double cityZoom = 13;
  static const double streetZoom = 16;

  /// The copy's city (MAP_CENTER), or Erbil when the setting is not a position.
  static GeoPoint get defaultCenter =>
      GeoPoint.tryParse(AppEnv.mapCenter) ?? const GeoPoint(36.1911, 44.0092);

  /// Widget tests have no map engine: they draw a plain surface instead.
  @visibleForTesting
  static bool usePlaceholder = false;

  @override
  State<AppMap> createState() => _AppMapState();
}

class _AppMapState extends State<AppMap> {
  AppMapController? _controller;

  void _created(MapLibreMapController map) {
    final controller = AppMapController(map);
    _controller = controller;
    widget.onCreated?.call(controller);
  }

  void _idle() {
    final center = _controller?.center;

    if (center != null) {
      widget.onSettled?.call(center);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (AppMap.usePlaceholder) {
      return ColoredBox(color: context.palette.surface2);
    }

    final style = mapStyleUrl(
      brightness: Theme.of(context).brightness,
      locale: Localizations.localeOf(context),
    );
    final start = widget.center ?? AppMap.defaultCenter;
    final rtl = Directionality.of(context) == TextDirection.rtl;

    return MapLibreMap(
      // A new style (mode or language changed) needs a new map.
      key: ValueKey(style),
      styleString: style,
      initialCameraPosition: CameraPosition(
        target: LatLng(start.latitude, start.longitude),
        zoom: widget.zoom,
      ),
      myLocationEnabled: widget.showMyLocation,
      trackCameraPosition: widget.onSettled != null,
      onCameraIdle: widget.onSettled == null ? null : _idle,
      compassEnabled: false,
      // The data's licence asks for the attribution; it sits at the start corner,
      // away from the map buttons at the end.
      attributionButtonPosition: rtl
          ? AttributionButtonPosition.bottomRight
          : AttributionButtonPosition.bottomLeft,
      onMapCreated: _created,
    );
  }
}
