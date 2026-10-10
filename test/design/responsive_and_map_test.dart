import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/config/app_env.dart';
import 'package:rider_app/core/l10n/app_locales.dart';
import 'package:rider_app/design/map/map_style.dart';
import 'package:rider_app/design/responsive/screen_size.dart';
import 'package:rider_app/design/responsive/text_scale_clamp.dart';

void main() {
  test('screen size classes', () {
    expect(ScreenSize.fromWidth(390), ScreenSize.compact);
    expect(ScreenSize.fromWidth(700), ScreenSize.medium);
    expect(ScreenSize.fromWidth(1024), ScreenSize.expanded);
  });

  test('map style follows mode and language', () {
    const base = AppEnv.mapTilesUrl;

    expect(mapStyleUrl(brightness: Brightness.light, locale: AppLocales.arabic),
        '$base/styles/light-ar.json');
    expect(mapStyleUrl(brightness: Brightness.dark, locale: AppLocales.english),
        '$base/styles/dark-en.json');
    expect(mapStyleUrl(brightness: Brightness.dark, locale: AppLocales.kurdish),
        '$base/styles/dark-ar.json');
  });

  testWidgets('text scale is held between the limits', (tester) async {
    late double scale;

    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(textScaler: TextScaler.linear(2.5)),
      child: TextScaleClamp(
        child: Builder(builder: (context) {
          scale = MediaQuery.textScalerOf(context).scale(10) / 10;
          return const SizedBox.shrink();
        }),
      ),
    ));

    expect(scale, TextScaleClamp.maxScale);
  });
}
