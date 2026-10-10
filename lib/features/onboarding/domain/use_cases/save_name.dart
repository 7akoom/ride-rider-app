import '../../../../core/error/result.dart';
import '../entities/rider_account.dart';
import '../repositories/rider_account_repository.dart';
import '../values/display_name.dart';

/// Makes the new rider's profile with the name they typed.
final class SaveName {
  const SaveName(this.accounts);

  final RiderAccountRepository accounts;

  Future<Result<RiderAccount>> call(DisplayName name) => accounts.create(name);
}
