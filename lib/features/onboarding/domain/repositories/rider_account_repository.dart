import '../../../../core/error/result.dart';
import '../entities/rider_account.dart';
import '../values/display_name.dart';

/// The signed-in person's rider profile.
abstract interface class RiderAccountRepository {
  /// The profile, or Ok(null) when the person has not made one yet.
  ///
  /// When the stored session is refused this returns a SessionExpiredFailure without
  /// ending the session app-wide: the caller decides where to go.
  Future<Result<RiderAccount?>> findMine();

  /// Makes the profile. If it already exists (a repeated tap, a second phone) the
  /// existing one is returned.
  Future<Result<RiderAccount>> create(DisplayName name);
}
