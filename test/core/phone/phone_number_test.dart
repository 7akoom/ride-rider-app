import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/format/digits.dart';
import 'package:rider_app/core/phone/phone_number.dart';

void main() {
  test('reads every usual way of writing an Iraqi mobile number', () {
    const expected = '+9647701234567';

    for (final typed in [
      '7701234567',
      '07701234567',
      '+964 770 123 4567',
      '00964-770-123-4567',
      '964 770 123 4567',
      '(770) 123-4567',
      '٠٧٧٠١٢٣٤٥٦٧',
      '۰۷۷۰۱۲۳۴۵۶۷',
    ]) {
      expect(PhoneNumber.tryParse(typed)?.e164, expected, reason: typed);
    }
  });

  test('refuses what cannot be an Iraqi mobile number', () {
    for (final typed in ['', '770123456', '77012345678', '6701234567', '+1 202 555 0100']) {
      expect(PhoneNumber.tryParse(typed), isNull, reason: typed);
    }
  });

  test('national part and equality', () {
    final a = PhoneNumber.tryParse('0770 123 4567')!;

    expect(a.national, '7701234567');
    expect(a, PhoneNumber.tryParse('+9647701234567'));
  });

  test('digits are converted to Western and everything else dropped', () {
    expect(westernDigitsOnly('a1-٢ ۳'), '123');
  });
}
