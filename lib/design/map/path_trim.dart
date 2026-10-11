import 'dart:math' as math;

import '../../core/location/geo_point.dart';

/// Metres between two close points (flat-earth: good for a city's distances).
double metresBetween(GeoPoint a, GeoPoint b) {
  final dy = (a.latitude - b.latitude) * 111000;
  final dx = (a.longitude - b.longitude) * 111000 * math.cos(a.latitude * math.pi / 180);

  return math.sqrt(dx * dx + dy * dy);
}

/// The heading from [from] to [to] in degrees clockwise from north (0 to 360).
double bearingBetween(GeoPoint from, GeoPoint to) {
  final dy = to.latitude - from.latitude;
  final dx = (to.longitude - from.longitude) * math.cos(from.latitude * math.pi / 180);
  final degrees = math.atan2(dx, dy) * 180 / math.pi;

  return (degrees + 360) % 360;
}

/// The part of [path] still ahead of a car at [at]: from the car, then the points after
/// the one nearest to it. Only points from [from] on are looked at, so the line never
/// grows back. Null when the car is farther than [offBy] metres from the path (it took
/// another road): the path is then kept whole.
({int index, List<GeoPoint> points})? pathAhead(
  List<GeoPoint> path,
  GeoPoint at, {
  int from = 0,
  double offBy = 80,
}) {
  if (path.length < 2 || from >= path.length) {
    return null;
  }

  var nearest = from;
  var best = double.infinity;

  for (var i = from; i < path.length; i++) {
    final distance = metresBetween(path[i], at);

    if (distance < best) {
      best = distance;
      nearest = i;
    }
  }

  if (best > offBy) {
    return null;
  }

  return (index: nearest, points: [at, ...path.skip(nearest + 1)]);
}
