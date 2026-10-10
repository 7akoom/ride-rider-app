import 'package:flutter/widgets.dart';

import '../../l10n/gen/app_localizations.dart';

export '../../l10n/gen/app_localizations.dart';

/// `context.l10n.someKey` instead of `AppLocalizations.of(context).someKey`.
///
/// Every piece of text the rider can see comes from here. Writing a literal string in a
/// widget is not allowed (scripts/check-hardcoded-strings.sh enforces it).
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
