import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/format/bidi.dart';
import 'package:rider_app/core/format/duration_format.dart';
import 'package:rider_app/core/phone/phone_number.dart';

void main() {
  test('countdowns are m:ss with Western digits', () {
    expect(formatCountdown(const Duration(seconds: 43)), '0:43');
    expect(formatCountdown(const Duration(seconds: 75)), '1:15');
    expect(formatCountdown(const Duration(seconds: -3)), '0:00');
  });

  test('phone numbers are grouped for reading and isolated in sentences', () {
    final phone = PhoneNumber.tryParse('07501234567')!;

    expect(phone.display, '+964 750 123 4567');
    expect(isolateLtr(phone.display), '\u2066+964 750 123 4567\u2069');
  });
}
