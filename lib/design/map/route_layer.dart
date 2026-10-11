import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../core/location/geo_point.dart';
import '../components/trip/route_markers.dart';
import '../tokens/palette.dart';
import 'map_route.dart';

/// Draws a [MapRoute] on a map whose style has loaded, and frames it. The markers keep
/// the colours of [RouteMarker]: ink pickup, hollow stops, brand destination. The
/// captain's car is a larger brand dot that moves on its own, without reframing.
final class RouteLayer {
  RouteLayer(this._map, this._palette);

  final MapLibreMapController _map;
  final Palette _palette;
  Circle? _vehicle;
  GeoPoint? _vehicleAt;

  /// Space between the route and the map's edges.
  static const double framePadding = 56;

  /// Draws [route] with the car at [vehicle] (none when null).
  Future<void> draw(MapRoute route, {GeoPoint? vehicle}) async {
    _vehicleAt = vehicle;
    await _map.clearLines();
    await _map.clearCircles();
    _vehicle = null;

    if (route.path.length > 1) {
      await _map.addLine(LineOptions(
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

    await placeVehicle(_vehicleAt);
    await _frame(route.extent);
  }

  /// Puts the car at [point], or takes it off the map when null.
  Future<void> placeVehicle(GeoPoint? point) async {
    _vehicleAt = point;
    final vehicle = _vehicle;

    if (point == null) {
      _vehicle = null;
      if (vehicle != null) {
        await _map.removeCircle(vehicle);
      }
      return;
    }

    if (vehicle != null) {
      await _map.updateCircle(vehicle, CircleOptions(geometry: _latLng(point)));
      return;
    }

    _vehicle = await _map.addCircle(CircleOptions(
      geometry: _latLng(point),
      circleRadius: 10,
      circleColor: _hex(_palette.brand),
      circleStrokeColor: _hex(_palette.ink),
      circleStrokeWidth: 4,
    ));
  }

  Color _fill(RoutePointKind kind) =>
      kind == RoutePointKind.pickup ? _palette.ink : _palette.brand;

  Future<void> _frame(List<GeoPoint> extent) async {
    if (extent.isEmpty) {
      return;
    }

    // One point has no extent to fit: the map goes to it at street level.
    if (extent.toSet().length == 1) {
      await _map.animateCamera(CameraUpdate.newLatLngZoom(_latLng(extent.first), 16));
      return;
    }

    final lats = extent.map((p) => p.latitude);
    final lngs = extent.map((p) => p.longitude);
    final bounds = LatLngBounds(
      southwest: LatLng(lats.reduce(math.min), lngs.reduce(math.min)),
      northeast: LatLng(lats.reduce(math.max), lngs.reduce(math.max)),
    );

    await _map.animateCamera(CameraUpdate.newLatLngBounds(
      bounds,
      left: framePadding,
      top: framePadding,
      right: framePadding,
      bottom: framePadding,
    ));
  }

  static LatLng _latLng(GeoPoint p) => LatLng(p.latitude, p.longitude);

  /// The style language's colour: "#RRGGBB".
  static String _hex(Color color) =>
      '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
}
