typedef JsonMap = Map<String, dynamic>;

/// The body of an answer as a JSON object; an empty map for anything else (an empty
/// body, or an HTML error page from a proxy).
JsonMap decodeJsonObject(Object? data) {
  if (data is Map<String, dynamic>) {
    return data;
  }

  if (data is Map) {
    return Map<String, dynamic>.from(data);
  }

  return <String, dynamic>{};
}

/// The JSON object at [key], or null when there is none.
JsonMap? objectAt(JsonMap json, String key) {
  final value = json[key];

  return value is Map ? decodeJsonObject(value) : null;
}

/// The non-empty text at [key]. An answer without it is malformed: the FormatException
/// becomes an UnexpectedFailure (reported, never shown).
String requiredText(JsonMap json, String key) {
  final value = json[key];

  if (value is String && value.isNotEmpty) {
    return value;
  }

  throw FormatException('missing $key in the answer');
}

/// A money amount at [key] (the backend sends decimal strings, "3000.00") in whole
/// currency units, or null when it is missing or not a number.
int? amountAt(JsonMap json, String key) {
  final value = json[key];
  final number = value is num ? value : num.tryParse(value is String ? value : '');

  return number?.round();
}

/// The money amount at [key]. An answer without it is malformed (see [requiredText]).
int requiredAmount(JsonMap json, String key) =>
    amountAt(json, key) ?? (throw FormatException('missing $key in the answer'));
