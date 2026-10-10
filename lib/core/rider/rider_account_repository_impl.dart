import '../error/failure.dart';
import '../error/failure_mapper.dart';
import '../error/guard.dart';
import '../error/result.dart';
import '../network/json.dart';
import '../security/session_storage.dart';
import 'display_name.dart';
import 'rider_account.dart';
import 'rider_account_api.dart';
import 'rider_account_repository.dart';

final class RiderAccountRepositoryImpl implements RiderAccountRepository {
  RiderAccountRepositoryImpl(this._api);

  final RiderAccountApi _api;

  @override
  Future<Result<RiderAccount?>> findMine() => guard(_findMine);

  @override
  Future<Result<RiderAccount>> create(DisplayName name) => guard(() async {
        final identityId = await _identityId();

        try {
          final json = await _api.create(
            identityId: identityId,
            displayName: name.value,
          );

          return await _remember(_accountIn(json));
        } on Object catch (error) {
          // Already made (a repeated tap, a second phone): use the existing one.
          if (mapToFailure(error) is! ConflictFailure) {
            rethrow;
          }

          return await _findMine() ?? (throw error);
        }
      });

  Future<RiderAccount?> _findMine() async {
    final identityId = await _identityId();

    try {
      return await _remember(_accountIn(await _api.findByIdentity(identityId)));
    } on Object catch (error) {
      if (mapToFailure(error) is NotFoundFailure) {
        return null;
      }

      rethrow;
    }
  }

  /// Without a stored identity there is no session to ask about.
  static Future<String> _identityId() async {
    final identityId = await SessionStorage.readIdentityId();

    if (identityId == null || identityId.isEmpty) {
      throw const SessionExpiredFailure();
    }

    return identityId;
  }

  /// Keeps the rider id for the screens that need it (trips, wallet).
  static Future<RiderAccount> _remember(RiderAccount account) async {
    await SessionStorage.saveRiderId(account.id);

    return account;
  }

  static RiderAccount _accountIn(JsonMap json) {
    final rider = objectAt(json, 'rider');

    if (rider == null) {
      throw const FormatException('missing rider in the answer');
    }

    final name = rider['displayName'];

    return RiderAccount(
      id: requiredText(rider, 'id'),
      displayName: name is String ? name : '',
    );
  }
}
