import 'package:rider_app/core/error/failure.dart';
import 'package:rider_app/core/error/result.dart';
import 'package:rider_app/core/location/geo_point.dart';
import 'package:rider_app/features/booking/domain/repositories/safety_repository.dart';

/// The safety routes, remembering what was asked.
class FakeSafety implements SafetyRepository {
  FakeSafety({this.link = 'https://ride.example/t/abc', this.failure});

  /// The share link; null when the copy has no page for it.
  String? link;
  Failure? failure;
  final List<String> calls = [];
  final List<String> reports = [];

  Result<T> _answer<T>(T value) {
    final f = failure;

    return f == null ? Ok(value) : Err(f);
  }

  @override
  Future<Result<String?>> shareLink(String tripId) async {
    calls.add('share');

    return _answer(link);
  }

  @override
  Future<Result<void>> stopSharing(String tripId) async {
    calls.add('stop');

    return _answer(null);
  }

  @override
  Future<Result<void>> raiseAlarm(String tripId, GeoPoint? at) async {
    calls.add('alarm');

    return _answer(null);
  }

  @override
  Future<Result<void>> report(String tripId, String text) async {
    reports.add(text);

    return _answer(null);
  }
}
