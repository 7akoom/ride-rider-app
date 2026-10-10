import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _read(String code) {
  final file = File('lib/l10n/app_$code.arb');

  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

Set<String> _messageKeys(Map<String, dynamic> arb) =>
    arb.keys.where((key) => !key.startsWith('@')).toSet();

void main() {
  const languages = ['en', 'ar', 'ku'];
  final template = _messageKeys(_read('en'));

  for (final code in languages) {
    test('app_$code.arb has exactly the template keys, none empty', () {
      final arb = _read(code);
      final keys = _messageKeys(arb);

      expect(keys.difference(template), isEmpty, reason: 'extra keys in $code');
      expect(template.difference(keys), isEmpty, reason: 'missing keys in $code');

      for (final key in keys) {
        expect((arb[key] as String).trim(), isNotEmpty, reason: '$code: $key');
      }
    });
  }
}
