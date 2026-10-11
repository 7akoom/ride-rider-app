import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/location/location_access.dart';
import '../repositories/safety_repository.dart';

/// A link to the trip for someone the rider trusts.
final class ShareTrip {
  const ShareTrip(this.safety);

  final SafetyRepository safety;

  Future<Result<String?>> call(String tripId) => safety.shareLink(tripId);
}

final class StopSharing {
  const StopSharing(this.safety);

  final SafetyRepository safety;

  Future<Result<void>> call(String tripId) => safety.stopSharing(tripId);
}

/// The alarm, with the rider's position when the phone gives it quickly. It goes even
/// without one: help must never wait for the GPS.
final class RaiseAlarm {
  const RaiseAlarm({required this.safety, required this.location});

  final SafetyRepository safety;
  final LocationAccess location;

  static const Duration positionWait = Duration(seconds: 3);

  Future<Result<void>> call(String tripId) async {
    final at = await location
        .currentPosition()
        .timeout(positionWait, onTimeout: () => null)
        .catchError((Object _) => null);

    return safety.raiseAlarm(tripId, at);
  }
}

/// A report for the safety team; it needs words.
final class ReportSafety {
  const ReportSafety(this.safety);

  final SafetyRepository safety;

  static const int maxText = 2000;

  Future<Result<void>> call(String tripId, String text) async {
    final words = text.trim();

    if (words.isEmpty || words.length > maxText) {
      return const Err(InvalidInputFailure());
    }

    return safety.report(tripId, words);
  }
}
