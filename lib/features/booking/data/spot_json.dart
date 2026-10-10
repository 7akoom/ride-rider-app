import '../../../core/location/geo_point.dart';
import '../../../core/network/json.dart';
import '../domain/entities/spot.dart';

/// Reading places from the backend's answers into spots.
abstract final class SpotJson {
  /// A place from search (map or curated): `name`, `displayName`, `category`.
  static Spot fromSearch(JsonMap json) {
    final name = _text(json['name']);
    final parts = _text(json['displayName'])
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    final title = name.isNotEmpty ? name : (parts.isEmpty ? '' : parts.first);
    final rest = parts.where((part) => part != title).take(2).join(', ');

    return Spot(
      point: GeoPoint.fromJson(json['coordinates']),
      kind: kindOf(_text(json['category'])),
      title: title.isEmpty ? null : title,
      detail: rest.isEmpty ? null : rest,
    );
  }

  /// A curated place: its name in [languageCode] when it has one.
  static Spot fromCurated(JsonMap json, String languageCode) {
    final names = json['names'];
    final translated = names is Map ? _text(names[languageCode]) : '';
    final name = translated.isNotEmpty ? translated : _text(json['name']);
    final address = _text(json['address']);

    return Spot(
      point: GeoPoint.fromJson(json['coordinates']),
      kind: kindOf(_text(json['category'])),
      title: name.isEmpty ? null : name,
      detail: address.isEmpty ? null : address,
    );
  }

  /// "airport" (search) and "PLACE_CATEGORY_AIRPORT" (curated list) alike.
  static SpotKind kindOf(String category) {
    final key = category.toLowerCase().replaceFirst('place_category_', '');

    return switch (key) {
      'airport' => SpotKind.airport,
      'mall' => SpotKind.mall,
      'hotel' => SpotKind.hotel,
      'hospital' => SpotKind.hospital,
      'university' => SpotKind.university,
      'landmark' => SpotKind.landmark,
      'station' => SpotKind.station,
      'government' => SpotKind.government,
      'restaurant' => SpotKind.restaurant,
      _ => SpotKind.other,
    };
  }

  static String _text(Object? value) => value is String ? value.trim() : '';
}
