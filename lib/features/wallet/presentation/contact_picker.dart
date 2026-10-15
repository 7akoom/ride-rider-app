import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the phone's own contact list and returns the numbers of the contact picked
/// (null when none was). The app never reads the contacts itself, so it asks for no
/// permission. Tests replace it.
typedef PickContactNumbers = Future<List<String>?> Function();

final pickContactNumbersProvider = Provider<PickContactNumbers>((ref) {
  final picker = FlutterNativeContactPicker();

  return () async {
    final contact = await picker.selectContact();

    return contact?.phoneNumbers;
  };
});
