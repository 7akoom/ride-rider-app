/// Wraps [text] as an isolated left-to-right run, so numbers, phone numbers and signs
/// keep their order inside Arabic and Kurdish sentences.
String isolateLtr(String text) => '\u2066$text\u2069';
