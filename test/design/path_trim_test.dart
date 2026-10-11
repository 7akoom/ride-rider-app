import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/location/geo_point.dart';
import 'package:rider_app/design/map/path_trim.dart';

void main() {
  // A road going north, a point about every 110 m.
  const road = [
    GeoPoint(36.190, 44.010),
    GeoPoint(36.191, 44.010),
    GeoPoint(36.192, 44.010),
    GeoPoint(36.193, 44.010),
  ];

  test('the road ahead starts at the car and drops what it has driven', () {
    const car = GeoPoint(36.1911, 44.0101);
    final ahead = pathAhead(road, car)!;

    expect(ahead.index, 1);
    expect(ahead.points, [car, road[2], road[3]]);
  });

  test('looking only forward, the road never grows back', () {
    // Nearest to the second point, but the car already passed the third.
    const back = GeoPoint(36.1913, 44.0100);

    expect(pathAhead(road, back)!.index, 1);
    expect(pathAhead(road, back, from: 2)!.index, 2);
  });

  test('a car off the road keeps the road whole', () {
    expect(pathAhead(road, const GeoPoint(36.2, 44.03)), isNull);
  });

  test('headings: north is 0, east is 90', () {
    expect(bearingBetween(road[0], road[1]), closeTo(0, 0.01));
    expect(bearingBetween(const GeoPoint(36.19, 44.01), const GeoPoint(36.19, 44.02)), closeTo(90, 0.01));
    expect(metresBetween(road[0], road[1]), closeTo(111, 1));
  });
}
