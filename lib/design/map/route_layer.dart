import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../core/location/geo_point.dart';
import '../components/trip/route_markers.dart';
import '../tokens/palette.dart';
import 'map_route.dart';
import 'path_trim.dart';

/// Draws a [MapRoute] on a map whose style has loaded, and frames it. The markers keep
/// the colours of [RouteMarker]: ink pickup, hollow stops, brand destination. Behind a
/// moving car the road it has driven is taken off ([trim]).
final class RouteLayer {
  RouteLayer(this._map, this._palette);

  final MapLibreMapController _map;
  final Palette _palette;
  Line? _line;
  List<GeoPoint> _path = const [];
  int _passed = 0;

  /// Space between the route and the map's edges, unless a screen asks for more.
  static const double framePadding = 56;

  /// Degrees around a single point framed alone: a few hundred metres.
  static const double _around = 0.003;

  /// Draws [route] and frames it, leaving [bottom] free under it.
  Future<void> draw(MapRoute route, {double bottom = framePadding}) async {
    await _map.clearLines();
    await _map.clearCircles();
    _line = null;
    _path = route.path;
    _passed = 0;

    if (route.path.length > 1) {
      _line = await _map.addLine(LineOptions(
        geometry: [for (final p in route.path) _latLng(p)],
        lineColor: _hex(_palette.info),
        lineWidth: 5,
        lineJoin: 'round',
      ));
    }

    for (final (point, kind) in route.points) {
      await _map.addCircle(CircleOptions(
        geometry: _latLng(point),
        circleRadius: 7,
        circleColor: _hex(kind == RoutePointKind.stop ? _palette.surface : _fill(kind)),
        circleStrokeColor: _hex(kind == RoutePointKind.stop ? _palette.textSecondary : _palette.surface),
        circleStrokeWidth: 3,
      ));
    }

    await _frame(route.extent, bottom);
  }

  /// The road is drawn from [car] on: what it has driven is gone.
  Future<void> trim(GeoPoint car) async {
    final line = _line;
    final ahead = pathAhead(_path, car, from: _passed);

    if (line == null || ahead == null) {
      return;
    }

    _passed = ahead.index;
    await _map.updateLine(line, LineOptions(geometry: [for (final p in ahead.points) _latLng(p)]));
  }

  Color _fill(RoutePointKind kind) =>
      kind == RoutePointKind.pickup ? _palette.ink : _palette.brand;

  Future<void> _frame(List<GeoPoint> extent, double bottom) async {
    if (extent.isEmpty) {
      return;
    }

    // One point has no extent: a few streets around it are framed instead, so it also
    // stands in the middle of the part of the map left open.
    final points = extent.toSet().length > 1
        ? extent
        : [
            for (final d in const [-_around, _around])
              GeoPoint(extent.first.latitude + d, extent.first.longitude + d),
          ];
    final lats = points.map((p) => p.latitude);
    final lngs = points.map((p) => p.longitude);
    final bounds = LatLngBounds(
      southwest: LatLng(lats.reduce(math.min), lngs.reduce(math.min)),
      northeast: LatLng(lats.reduce(math.max), lngs.reduce(math.max)),
    );

    await _map.animateCamera(CameraUpdate.newLatLngBounds(
      bounds,
      left: framePadding,
      top: framePadding,
      right: framePadding,
      bottom: bottom,
    ));
  }

  static LatLng _latLng(GeoPoint p) => LatLng(p.latitude, p.longitude);

  /// The style language's colour: "#RRGGBB".
  static String _hex(Color color) =>
      '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
}
