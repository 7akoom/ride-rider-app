import 'package:rider_app/core/error/failure.dart';
import 'package:rider_app/core/error/result.dart';
import 'package:rider_app/core/location/geo_point.dart';
import 'package:rider_app/features/booking/domain/entities/captain.dart';
import 'package:rider_app/features/booking/domain/repositories/captain_repository.dart';

const someCaptain = Captain(
  name: 'Salem Suleiman',
  rating: 4.9,
  make: 'Toyota',
  model: 'Corolla',
  color: 'white',
  plate: '22 A 25626',
);

/// The captain of every trip, near the pickup unless told otherwise.
class FakeCaptains implements CaptainRepository {
  FakeCaptains({this.captainFailure, this.at = const GeoPoint(36.195, 44.015)});

  Failure? captainFailure;

  /// Where the captain is; null while their phone has not reported.
  GeoPoint? at;
  int captainReads = 0;

  @override
  Future<Result<Captain>> captain(String tripId) async {
    captainReads++;
    final f = captainFailure;

    return f == null ? const Ok(someCaptain) : Err(f);
  }

  @override
  Future<Result<GeoPoint?>> position(String tripId) async => Ok(at);
}
