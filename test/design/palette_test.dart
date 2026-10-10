import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/design/tokens/brand.dart';
import 'package:rider_app/design/tokens/contrast.dart';
import 'package:rider_app/design/tokens/palette.dart';
import 'package:rider_app/design/tokens/palettes.dart';

void _expectReadable(Color text, Color background, String what) {
  expect(contrastRatio(text, background), greaterThanOrEqualTo(4.5), reason: what);
}

void main() {
  final brands = {
    'lenda': Brand.lenda,
    'navy': Brand.resolve(brandColor: '#1E3A8A'),
    'lemon': Brand.resolve(brandColor: '#FFF59D'),
  };

  for (final MapEntry(key: name, value: brand) in brands.entries) {
    final modes = {'light': Palettes.light(brand), 'dark': Palettes.dark(brand)};

    for (final MapEntry(key: mode, value: p) in modes.entries) {
      test('$name/$mode: text, brand and status colours are readable', () {
        _expectReadable(p.textPrimary, p.background, 'text on background');
        _expectReadable(p.textPrimary, p.surface, 'text on surface');
        _expectReadable(p.textSecondary, p.surface, 'secondary text on surface');
        _expectReadable(p.onBrand, p.brand, 'text on brand');
        _expectReadable(p.brandStrong, p.surface, 'brand text on surface');
        _expectReadable(p.onInk, p.ink, 'text on ink');
        _expectReadable(p.danger, p.surface, 'danger on surface');
        _expectReadable(p.success, p.surface, 'success on surface');
      });
    }
  }

  test('lerp moves between palettes', () {
    final light = Palettes.light(Brand.lenda);
    final dark = Palettes.dark(Brand.lenda);

    expect(light.lerp(dark, 0).background, light.background);
    expect(light.lerp(dark, 1).background, dark.background);
    expect(light.lerp(null, 0.5), same(light));
    expect(light.copyWith(), isA<Palette>());
  });
}
