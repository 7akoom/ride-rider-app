import '../../../core/error/guard.dart';
import '../../../core/error/result.dart';
import '../../../core/network/json.dart';
import '../../../core/rider/rider_id.dart';
import '../domain/entities/statement.dart';
import '../domain/entities/wallet_movement.dart';
import '../domain/entities/wallet_overview.dart';
import '../domain/repositories/wallet_repository.dart';
import 'wallet_api.dart';
import 'wallet_json.dart';

final class WalletRepositoryImpl implements WalletRepository {
  WalletRepositoryImpl(this._api);

  final WalletApi _api;

  @override
  Future<Result<WalletOverview>> overview() => guard(() async {
        final riderId = await riderIdOrSignIn();
        final (wallet, dues) = (await _api.wallet(riderId), await _api.dues(riderId));

        return WalletOverview(
          balance: amountAt(objectAt(wallet, 'wallet') ?? const {}, 'balance') ?? 0,
          owed: amountAt(dues, 'outstanding') ?? 0,
          canRequestTrips: dues['canRequestTrips'] != false,
        );
      });

  @override
  Future<Result<List<WalletMovement>>> recent(int limit) => guard(() async {
        final json = await _api.transactions(await riderIdOrSignIn(), limit);

        return WalletJson.movementsOf(json['transactions']);
      });

  @override
  Future<Result<StatementPage>> statement({
    required DateTime from,
    required DateTime to,
    MovementFilter filter = MovementFilter.all,
    String? page,
  }) =>
      guard(() async {
        final json = await _api.statement(await riderIdOrSignIn(), {
          'from': from.toUtc().toIso8601String(),
          'to': to.toUtc().toIso8601String(),
          'pageSize': 30,
          ...WalletJson.filterOf(filter),
          if (page != null) 'pageToken': page,
        });

        return WalletJson.statementOf(json);
      });
}
