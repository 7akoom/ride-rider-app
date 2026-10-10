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
