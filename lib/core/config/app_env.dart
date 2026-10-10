import 'package:flutter/foundation.dart';

/// Something about the build's configuration that makes it unsafe or unusable.
enum EnvProblem {
  /// The API address is not a valid absolute URL.
  invalidApiUrl,

  /// A release build would talk to the API over plain HTTP.
  insecureApiUrl,

  /// A release build would load the map over plain HTTP.
  insecureTilesUrl,
}

/// Values set per build with `--dart-define` (one build per investor's copy).
///
/// Example:
///   flutter build apk --release --obfuscate --split-debug-info=build/symbols \
///     --dart-define=API_BASE_URL=https://ride-api.example.com \
///     --dart-define=MAP_TILES_URL=https://ride-tiles.example.com \
///     --dart-define=APP_NAME=Ride
abstract final class AppEnv {
  /// The API gateway. The default reaches a backend on the developer's computer from
  /// the Android emulator, and only debug builds accept plain HTTP.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  /// The map server (styles, tiles, fonts).
  static const String mapTilesUrl = String.fromEnvironment(
    'MAP_TILES_URL',
    defaultValue: 'https://ride-tiles.lenda-agency.com',
  );

  /// The product name shown by the system (task switcher). Not translated: it is a
  /// brand name.
  static const String appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'Ride',
  );

  /// The problems with this build's configuration; empty when it is fine to run.
  static List<EnvProblem> problems() => check(
        apiBaseUrl: apiBaseUrl,
        mapTilesUrl: mapTilesUrl,
        isRelease: kReleaseMode,
      );

  @visibleForTesting
  static List<EnvProblem> check({
    required String apiBaseUrl,
    required String mapTilesUrl,
    required bool isRelease,
  }) {
    final found = <EnvProblem>[];
    final api = Uri.tryParse(apiBaseUrl);

    if (api == null || !api.hasScheme || api.host.isEmpty) {
      found.add(EnvProblem.invalidApiUrl);
    } else if (isRelease && api.scheme != 'https') {
      found.add(EnvProblem.insecureApiUrl);
    }

    final tiles = Uri.tryParse(mapTilesUrl);
    if (isRelease && (tiles == null || tiles.scheme != 'https')) {
      found.add(EnvProblem.insecureTilesUrl);
    }

    return found;
  }
}
