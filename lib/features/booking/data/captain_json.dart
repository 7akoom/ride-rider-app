import '../../../core/location/geo_point.dart';
import '../../../core/network/json.dart';
import '../domain/entities/captain.dart';

/// Reads the gateway's answers about a trip's captain. Fields left out are empty.
abstract final class CaptainJson {
  static Captain captainOf(JsonMap answer) {
    final json = objectAt(answer, 'driver') ?? const <String, dynamic>{};
    final car = objectAt(json, 'vehicle') ?? const <String, dynamic>{};
    final average = json['ratingAverage'];
    final count = json['ratingCount'];

    return Captain(
      name: _text(json['displayName']),
      photoUrl: _text(json['photoUrl']),
      rating: average is num && average > 0 && count is num && count > 0
          ? average.toDouble()
          : null,
      make: _text(car['make']),
      model: _text(car['model']),
      color: _text(car['color']),
      plate: _text(car['plateNumber']),
    );
  }

  /// The position in the answer, or null when it has none.
  static GeoPoint? positionOf(JsonMap answer) {
    final location = objectAt(answer, 'location');

    return location == null ? null : GeoPoint.fromJson(location);
  }

  static String _text(Object? value) => value is String ? value.trim() : '';
}
