import '../../../../core/error/result.dart';
import '../../../../core/rider/display_name.dart';
import '../../../../core/rider/rider_account_repository.dart';
import '../entities/next_step.dart';
import 'account_step.dart';

/// Makes the new rider's profile with the name they typed, then says where to go
/// (the location screen once, or the app).
final class SaveName {
  const SaveName({required this.accounts, required this.accountStep});

  final RiderAccountRepository accounts;
  final AccountStep accountStep;

  Future<Result<NextStep>> call(DisplayName name) async {
    return switch (await accounts.create(name)) {
      Ok(:final value) => Ok(await accountStep.after(value)),
      Err(:final failure) => Err(failure),
    };
  }
}
