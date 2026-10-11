import '../../../core/error/guard.dart';
import '../../../core/error/result.dart';
import '../../../core/location/geo_point.dart';
import '../domain/repositories/safety_repository.dart';
import 'safety_api.dart';

final class SafetyRepositoryImpl implements SafetyRepository {
  SafetyRepositoryImpl(this._api);

  final SafetyApi _api;

  /// The support category the safety team answers (support-service seeds it).
  static const String safetyCategory = 'safety';

  @override
  Future<Result<String?>> shareLink(String tripId) => guard(() async {
        final url = (await _api.share(tripId))['url'];

        // An http(s) link only: anything else would not open for the person it goes to.
        return url is String && url.startsWith('http') ? url.trim() : null;
      });

  @override
  Future<Result<void>> stopSharing(String tripId) => guard(() => _api.stopSharing(tripId));

  @override
  Future<Result<void>> raiseAlarm(String tripId, GeoPoint? at) => guard(
        () => _api.alarm(tripId, {
          'triggeredBy': 'SOS_TRIGGERED_BY_RIDER',
          if (at != null) 'location': at.toJson(),
        }),
      );

  @override
  Future<Result<void>> report(String tripId, String text) => guard(
        () => _api.ticket({
          'audience': 'AUDIENCE_RIDER',
          'categoryKey': safetyCategory,
          'body': text,
          'tripId': tripId,
        }),
      );
}
