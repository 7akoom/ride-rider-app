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
