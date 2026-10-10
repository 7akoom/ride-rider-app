import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Adds the bundled fonts' licence to the app's licence list, as the SIL Open Font
/// License asks when the fonts are distributed with software.
void registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString('assets/fonts/OFL.txt');

    yield LicenseEntryWithLineBreaks(const ['IBM Plex'], text);
  });
}
