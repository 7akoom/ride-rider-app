import 'dart:async';

import 'package:maplibre_gl/maplibre_gl.dart';

import '../../core/error/error_reporter.dart';
import '../../core/location/geo_point.dart';
import '../tokens/palette.dart';
import 'map_route.dart';
import 'route_layer.dart';
import 'vehicle_marker.dart';

/// What a screen draws on one map: a route and the captain's car. The map's engine
/// takes one change at a time (overlapping ones can bring the app down), so every
/// change waits for the one before it.
final class MapLayers {
  MapLayers(MapLibreMapController map, Palette palette, double pixelRatio)
      : _route = RouteLayer(map, palette),
        _car = VehicleMarker(map, palette, pixelRatio);

  final RouteLayer _route;
  final VehicleMarker _car;
  Future<void> _queue = Future.value();
  Timer? _glide;

  /// A new position is reached in this many small moves, so the car slides.
  static const int glideSteps = 8;
  static const Duration glideStep = Duration(milliseconds: 250);

  Future<void> _run(Future<void> Function() change) {
    final next = _queue.then((_) => change()).catchError((Object error, StackTrace stack) {
      // The map was closed or is not ready: the next change draws it again.
      ErrorReporter.report(error, stack);
    });
    _queue = next;

    return next;
  }

  /// Once the style is there: the car's picture.
  Future<void> ready() => _run(_car.prepare);

  /// Draws [route], frames it with [bottom] left free under it, and puts the car at [car].
  Future<void> draw(MapRoute route, {GeoPoint? car, required double bottom}) {
    _glide?.cancel();

    return _run(() async {
      await _route.draw(route, bottom: bottom);
      await _car.place(car);
      if (car != null) {
        await _route.trim(car);
      }
    });
  }

  /// Slides the car to [to] (or takes it off when null), the road behind it going.
  void moveCar(GeoPoint? to) {
    _glide?.cancel();
    final from = _car.at;

    if (to == null || from == null) {
      unawaited(_run(() => _car.place(to)));
      return;
    }

    var step = 0;
    _glide = Timer.periodic(glideStep, (timer) {
      step++;
      final t = step / glideSteps;
      final point = GeoPoint(
        from.latitude + (to.latitude - from.latitude) * t,
        from.longitude + (to.longitude - from.longitude) * t,
      );
      unawaited(_run(() async {
        await _car.place(point);
        await _route.trim(point);
      }));

      if (step >= glideSteps) {
        timer.cancel();
      }
    });
  }

  void dispose() => _glide?.cancel();
}
