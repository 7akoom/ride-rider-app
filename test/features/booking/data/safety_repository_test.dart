import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/error/result.dart';
import 'package:rider_app/core/location/geo_point.dart';
import 'package:rider_app/core/network/api_client.dart';
import 'package:rider_app/features/booking/data/rides_repository_impl.dart';
import 'package:rider_app/features/booking/data/safety_api.dart';
import 'package:rider_app/features/booking/data/safety_repository_impl.dart';
import 'package:rider_app/features/booking/domain/entities/cancellation.dart';

class _FakeSafetyApi implements SafetyApi {
  JsonMap shareAnswer = {};
  final List<(String, JsonMap?)> sent = [];

  @override
  Future<JsonMap> share(String tripId) async {
    sent.add(('share', null));

    return shareAnswer;
  }

  @override
  Future<JsonMap> stopSharing(String tripId) async {
    sent.add(('stop', null));

    return {'stopped': 1};
  }

  @override
  Future<JsonMap> alarm(String tripId, JsonMap body) async {
    sent.add(('alarm', body));

    return {};
  }

  @override
  Future<JsonMap> ticket(JsonMap body) async {
    sent.add(('ticket', body));

    return {};
  }
}

void main() {
  test('a share link is the server\'s; none when the copy has no page for it', () async {
    final api = _FakeSafetyApi()..shareAnswer = {'token': 't', 'url': 'https://ride.example/t/t'};
    final safety = SafetyRepositoryImpl(api);

    expect((await safety.shareLink('trip-1') as Ok<String?>).value, 'https://ride.example/t/t');

    api.shareAnswer = {'token': 't', 'url': ''};
    expect((await safety.shareLink('trip-1') as Ok<String?>).value, isNull);
  });

  test('the alarm says the rider raised it and where they are', () async {
    final api = _FakeSafetyApi();

    await SafetyRepositoryImpl(api).raiseAlarm('trip-1', const GeoPoint(36.2, 44.01));
    await SafetyRepositoryImpl(api).raiseAlarm('trip-1', null);

    expect(api.sent[0].$2, {
      'triggeredBy': 'SOS_TRIGGERED_BY_RIDER',
      'location': {'latitude': 36.2, 'longitude': 44.01},
    });
    expect(api.sent[1].$2, {'triggeredBy': 'SOS_TRIGGERED_BY_RIDER'});
  });

  test('a report is an urgent safety ticket about the trip', () async {
    final api = _FakeSafetyApi();

    await SafetyRepositoryImpl(api).report('trip-1', 'He drove too fast');

    expect(api.sent.single.$2, {
      'audience': 'AUDIENCE_RIDER',
      'categoryKey': 'safety',
      'body': 'He drove too fast',
      'tripId': 'trip-1',
    });
  });

  test('the reason staff read for each way of cancelling', () {
    expect(RidesRepositoryImpl.reasonOf(null), RidesRepositoryImpl.cancelReason);
    expect(
      RidesRepositoryImpl.reasonOf(const Cancellation(CancelReason.captainLate)),
      'rider: the captain was late',
    );
    expect(
      RidesRepositoryImpl.reasonOf(Cancellation.of(CancelReason.other, '  wrong car  ')),
      'rider: wrong car',
    );
  });

  test('another reason needs words, and is cut to its limit', () {
    expect(Cancellation.of(CancelReason.other, '   '), isNull);
    expect(Cancellation.of(CancelReason.changedMind, 'ignored')!.text, isEmpty);
    expect(Cancellation.of(CancelReason.other, 'x' * 300)!.text.length, Cancellation.maxText);
  });
}
