import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/design/tokens/base_colors.dart';
import 'package:rider_app/design/tokens/brand.dart';
import 'package:rider_app/design/tokens/contrast.dart';

void main() {
  group('contrast', () {
    test('black on white is 21:1', () {
      expect(contrastRatio(const Color(0xFF000000), const Color(0xFFFFFFFF)),
          closeTo(21, 0.01));
    });

    test('ink reads better than white on the gold', () {
      expect(bestTextOn(const Color(0xFFF3D59A), dark: BaseColors.ink), BaseColors.ink);
    });

    test('withContrast reaches 4.5:1 when the colour is too light', () {
      const gold = Color(0xFFF3D59A);
      final fixed = withContrast(gold, BaseColors.lightSurface);

      expect(contrastRatio(fixed, BaseColors.lightSurface), greaterThanOrEqualTo(4.5));
    });
  });

  group('Brand', () {
    test('the default build uses the Lenda gold from the brief', () {
      expect(Brand.resolve(brandColor: '#F3D59A'), Brand.lenda);
    });

    test('an invalid colour falls back to the default', () {
      expect(Brand.resolve(brandColor: 'gold'), Brand.lenda);
    });

    for (final hex in ['#1E3A8A', '#FFF59D', '#E11D48', '#10B981']) {
      test('$hex: every derived shade is readable', () {
        final brand = Brand.resolve(brandColor: hex);

        expect(contrastRatio(brand.onFill, brand.fill), greaterThanOrEqualTo(4.5));
        expect(contrastRatio(brand.strongOnLight, BaseColors.lightSurface),
            greaterThanOrEqualTo(4.5));
        expect(contrastRatio(brand.strongOnDark, BaseColors.darkSurface),
            greaterThanOrEqualTo(4.5));
      });
    }

    test('a dark brand gets white text, a light one ink', () {
      expect(Brand.resolve(brandColor: '#1E3A8A').onFill, BaseColors.white);
      expect(Brand.resolve(brandColor: '#FFF59D').onFill, BaseColors.ink);
    });

    test('an explicit strong colour is kept when it is readable', () {
      final brand = Brand.resolve(brandColor: '#F3D59A', brandStrongColor: '#6F5214');

      expect(brand.strongOnLight, const Color(0xFF6F5214));
    });
  });
}
