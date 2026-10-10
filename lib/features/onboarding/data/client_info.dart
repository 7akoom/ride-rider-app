import 'package:flutter/foundation.dart';

import '../../../core/config/app_env.dart';

/// What the app tells the backend about itself when signing in, so the rider can see
/// and end their sessions per device later.
final class ClientInfo {
  const ClientInfo._({required this.platform});

  final String platform;

  String get clientId => AppEnv.clientId;
  String get appVersion => AppEnv.appVersion;

  /// Not shown to anyone as a sentence: a technical label in the session list.
  String get deviceName => '${AppEnv.clientId} ($platform)';

  static ClientInfo current() => ClientInfo._(
        platform: switch (defaultTargetPlatform) {
          TargetPlatform.android => 'android',
          TargetPlatform.iOS => 'ios',
          _ => 'other',
        },
      );
}
