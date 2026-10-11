import '../../../core/error/failure.dart';
import '../../../core/error/guard.dart';
import '../../../core/error/result.dart';
import '../../../core/location/geo_point.dart';
import '../domain/entities/captain.dart';
import '../domain/repositories/captain_repository.dart';
import 'captain_api.dart';
import 'captain_json.dart';

final class CaptainRepositoryImpl implements CaptainRepository {
  CaptainRepositoryImpl(this._api);

  final CaptainApi _api;

  @override
  Future<Result<Captain>> captain(String tripId) =>
      guard(() async => CaptainJson.captainOf(await _api.captain(tripId)));

  @override
  Future<Result<GeoPoint?>> position(String tripId) async {
    final result = await guard(() async => CaptainJson.positionOf(await _api.position(tripId)));

    // 404: the captain's phone has not reported for a while; the last position stays.
    return switch (result) {
      Err(failure: NotFoundFailure()) => const Ok(null),
      _ => result,
    };
  }
}
