import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/security/redactor.dart';

void main() {
  test('removes bearer tokens and JWTs', () {
    const jwt = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIn0.abc_DEF-123';

    final out = Redactor.redact('Authorization: Bearer $jwt and $jwt');

    expect(out, isNot(contains('eyJ')));
  });

  test('removes token fields in JSON', () {
    final out = Redactor.redact('{"refreshToken":"secret-value","pin":"1234"}');

    expect(out, isNot(contains('secret-value')));
    expect(out, isNot(contains('1234')));
    expect(out, contains('"refreshToken":"***"'));
  });

  test('removes phone numbers and e-mail addresses', () {
    final out = Redactor.redact('call +964 750 123 4567 or a.b@example.com');

    expect(out, isNot(contains('4567')));
    expect(out, isNot(contains('example.com')));
  });

  test('leaves ordinary text alone', () {
    expect(Redactor.redact('trip not found'), 'trip not found');
  });
}
