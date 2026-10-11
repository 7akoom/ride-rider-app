import '../../../../core/error/result.dart';
import '../../../../core/location/geo_point.dart';
import '../entities/captain.dart';

/// The captain of the rider's trip: who they are and where they are now.
abstract interface class CaptainRepository {
  Future<Result<Captain>> captain(String tripId);

  /// Their last position; null while their phone has not reported one lately.
  Future<Result<GeoPoint?>> position(String tripId);
}
