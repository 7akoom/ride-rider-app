import '../../../core/error/result.dart';
import '../../../core/location/geo_point.dart';

/// Where one of the rider's completed trips ended.
final class RecentDestination {
  const RecentDestination({required this.point, this.address = '', this.lastTripAt});

  final GeoPoint point;

  /// As the rider picked it; empty for trips from before addresses.
  final String address;
  final DateTime? lastTripAt;
}

abstract interface class RecentDestinationsRepository {
  /// Newest first, at most [limit].
  Future<Result<List<RecentDestination>>> recent({int limit = 1});
}
