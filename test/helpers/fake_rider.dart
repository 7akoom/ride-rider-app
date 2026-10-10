import 'package:rider_app/core/error/failure.dart';
import 'package:rider_app/core/error/result.dart';
import 'package:rider_app/core/rider/display_name.dart';
import 'package:rider_app/core/rider/rider_account.dart';
import 'package:rider_app/core/rider/rider_account_repository.dart';

class FakeAccounts implements RiderAccountRepository {
  FakeAccounts(this.found, {this.createFailure});

  Result<RiderAccount?> found;

  /// When set, making the profile fails with it.
  Failure? createFailure;

  @override
  Future<Result<RiderAccount?>> findMine() async => found;

  @override
  Future<Result<RiderAccount>> create(DisplayName name) async {
    final failure = createFailure;

    return failure == null
        ? Ok(RiderAccount(id: 'r1', displayName: name.value))
        : Err(failure);
  }
}

const someone = RiderAccount(id: 'r1', displayName: 'Salem');
