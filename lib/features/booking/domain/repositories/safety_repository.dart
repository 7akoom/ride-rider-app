import '../../../../core/error/result.dart';
import '../../../../core/location/geo_point.dart';

/// Keeping the rider safe on a trip: links for people they trust, the alarm to the
/// safety team, and reports about what went wrong.
abstract interface class SafetyRepository {
  /// A new link to follow the trip; null when the copy has no page to open it.
  Future<Result<String?>> shareLink(String tripId);

  /// Every link to the trip stops working.
  Future<Result<void>> stopSharing(String tripId);

  /// Tells the safety team now, with where the rider is when known.
  Future<Result<void>> raiseAlarm(String tripId, GeoPoint? at);

  /// An urgent ticket for the safety team about the trip.
  Future<Result<void>> report(String tripId, String text);
}
