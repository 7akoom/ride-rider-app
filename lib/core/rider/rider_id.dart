import '../error/failure.dart';
import '../security/session_storage.dart';

/// The signed-in rider's id; a missing one means signing in again.
Future<String> riderIdOrSignIn() async {
  final riderId = await SessionStorage.readRiderId();

  if (riderId == null || riderId.isEmpty) {
    throw const SessionExpiredFailure();
  }

  return riderId;
}
