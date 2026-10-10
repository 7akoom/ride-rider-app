/// A position on the map.
class GeoPoint {
  final double latitude;
  final double longitude;

  const GeoPoint(this.latitude, this.longitude);

  factory GeoPoint.fromJson(Object? json) {
    if (json is Map) {
      final lat = json['latitude'];
      final lng = json['longitude'];

      return GeoPoint(
        lat is num ? lat.toDouble() : 0,
        lng is num ? lng.toDouble() : 0,
      );
    }

    return const GeoPoint(0, 0);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
      };

  /// Reads "latitude,longitude" (as in the MAP_CENTER build setting); null when it is
  /// not a position on Earth.
  static GeoPoint? tryParse(String text) {
    final parts = text.split(',');
    if (parts.length != 2) {
      return null;
    }

    final latitude = double.tryParse(parts[0].trim());
    final longitude = double.tryParse(parts[1].trim());
    if (latitude == null || longitude == null) {
      return null;
    }

    if (latitude.abs() > 90 || longitude.abs() > 180) {
      return null;
    }

    return GeoPoint(latitude, longitude);
  }

  /// True for the (0, 0) the backend sends when a position is missing.
  bool get isEmpty => latitude == 0 && longitude == 0;

  @override
  bool operator ==(Object other) =>
      other is GeoPoint && other.latitude == latitude && other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);
}
