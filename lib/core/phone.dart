// Moved to lib/core/phone/phone_number.dart. Kept until the legacy screens are migrated.
import 'phone/phone_number.dart';

/// The number in international form (+9647XXXXXXXXX), or null if it cannot be one.
String? normalizeIraqPhone(String input) => PhoneNumber.tryParse(input)?.e164;
