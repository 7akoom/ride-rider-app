import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/config/app_env.dart';

void main() {
  const tiles = 'https://tiles.example.com';

  test('release builds refuse plain HTTP', () {
    expect(
      AppEnv.check(apiBaseUrl: 'http://api.example.com', mapTilesUrl: tiles, isRelease: true),
      [EnvProblem.insecureApiUrl],
    );
    expect(
      AppEnv.check(
        apiBaseUrl: 'https://api.example.com',
        mapTilesUrl: 'http://tiles.example.com',
        isRelease: true,
      ),
      [EnvProblem.insecureTilesUrl],
    );
  });

  test('debug builds may use plain HTTP to a local backend', () {
    expect(
      AppEnv.check(apiBaseUrl: 'http://10.0.2.2:8080', mapTilesUrl: tiles, isRelease: false),
      isEmpty,
    );
  });

  test('a malformed API address is always a problem', () {
    expect(
      AppEnv.check(apiBaseUrl: 'not a url', mapTilesUrl: tiles, isRelease: false),
      [EnvProblem.invalidApiUrl],
    );
  });

  test('a correct release configuration passes', () {
    expect(
      AppEnv.check(apiBaseUrl: 'https://api.example.com', mapTilesUrl: tiles, isRelease: true),
      isEmpty,
    );
  });

  test('brand colours must be #RRGGBB', () {
    List<EnvProblem> withBrand(String brand, [String strong = '']) => AppEnv.check(
          apiBaseUrl: 'https://api.example.com',
          mapTilesUrl: tiles,
          isRelease: true,
          brandColor: brand,
          brandStrongColor: strong,
        );

    expect(withBrand('#1E3A8A'), isEmpty);
    expect(withBrand('1E3A8A', '#123456'), isEmpty);
    expect(withBrand('gold'), [EnvProblem.invalidBrandColor]);
    expect(withBrand('#1E3A8A', '#12'), [EnvProblem.invalidBrandColor]);
  });
}
