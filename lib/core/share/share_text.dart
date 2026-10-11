import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

/// Opens the phone's share sheet with [text] (WhatsApp, messages...). Tests replace it.
typedef ShareText = Future<void> Function(String text);

final shareTextProvider = Provider<ShareText>(
  (ref) => (text) async {
    await SharePlus.instance.share(ShareParams(text: text));
  },
);
