import 'package:rider_app/core/network/api_client.dart';
import 'package:rider_app/features/booking/data/rides_api.dart';

/// The gateway's rides routes, answering what a test sets.
class FakeRidesApi implements RidesApi {
  JsonMap quoted = {};
  JsonMap walletAnswer = {};
  JsonMap requested = {
    'trip': {'id': 'trip-9'},
  };
  JsonMap followed = {};
  Object? activeError;
  JsonMap? sent;
  String? cancelReason;

  @override
  Future<JsonMap> quotes(JsonMap body) async {
    sent = body;

    return quoted;
  }

  @override
  Future<JsonMap> wallet(String riderId) async => walletAnswer;

  @override
  Future<JsonMap> requestTrip(JsonMap body) async {
    sent = body;

    return requested;
  }

  @override
  Future<JsonMap> trip(String id) async => followed;

  @override
  Future<JsonMap> activeTrip(String riderId) async =>
      activeError == null ? followed : throw activeError!;

  @override
  Future<JsonMap> cancelTrip(String id, String reason) async {
    cancelReason = reason;

    return followed;
  }
}
