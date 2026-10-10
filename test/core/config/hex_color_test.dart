import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/config/hex_color.dart';

void main() {
  test('reads #RRGGBB and RRGGBB as opaque colours', () {
    expect(parseHexColor('#F3D59A'), 0xFFF3D59A);
    expect(parseHexColor('f3d59a'), 0xFFF3D59A);
    expect(parseHexColor(' #05070F '), 0xFF05070F);
  });

  test('rejects anything else', () {
    for (final bad in ['', '#FFF', '#GGGGGG', '#F3D59A00', 'gold']) {
      expect(parseHexColor(bad), isNull, reason: bad);
    }
  });
}
