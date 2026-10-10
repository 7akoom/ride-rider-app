import 'package:flutter/widgets.dart';

import '../../core/config/app_env.dart';

/// The map style for the current mode and language, from the platform's map server
/// (four styles: light-ar, light-en, dark-ar, dark-en; Kurdish uses the Arabic-script
/// labels).
String mapStyleUrl({required Brightness brightness, required Locale locale}) {
  final mode = brightness == Brightness.dark ? 'dark' : 'light';
  final labels = locale.languageCode == 'en' ? 'en' : 'ar';

  return '${AppEnv.mapTilesUrl}/styles/$mode-$labels.json';
}
