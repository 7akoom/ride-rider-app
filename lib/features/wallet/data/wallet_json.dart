import '../../../core/network/json.dart';
import '../domain/entities/statement.dart';
import '../domain/entities/top_up.dart';
import '../domain/entities/voucher_credit.dart';
import '../domain/entities/wallet_movement.dart';

/// Reads the gateway's wallet answers. Amounts are decimal strings; missing ones are 0.
abstract final class WalletJson {
  static MovementKind kindOf(Object? type) => switch (type) {
        'TRANSACTION_TYPE_TOP_UP' => MovementKind.topUp,
        'TRANSACTION_TYPE_TRIP_PAYMENT' => MovementKind.tripPayment,
        'TRANSACTION_TYPE_CHANGE_CREDIT' => MovementKind.change,
        'TRANSACTION_TYPE_TRANSFER_OUT' => MovementKind.transferOut,
        'TRANSACTION_TYPE_TRANSFER_IN' => MovementKind.transferIn,
        'TRANSACTION_TYPE_DUE_PAYMENT' => MovementKind.duePayment,
        'TRANSACTION_TYPE_VOUCHER' => MovementKind.voucher,
        'TRANSACTION_TYPE_REFUND' => MovementKind.refund,
        'TRANSACTION_TYPE_TIP' => MovementKind.tip,
        'TRANSACTION_TYPE_ADJUSTMENT' => MovementKind.adjustment,
        _ => MovementKind.other,
      };

  static WalletMovement movementOf(JsonMap json) => WalletMovement(
        id: requiredText(json, 'id'),
        kind: kindOf(json['type']),
        amount: amountAt(json, 'amount') ?? 0,
        balanceAfter: amountAt(json, 'balanceAfter'),
        at: DateTime.tryParse(_text(json['createdAt'])) ?? DateTime.fromMillisecondsSinceEpoch(0),
        tripId: _text(json['tripId']),
      );

  static List<WalletMovement> movementsOf(Object? items) => [
        if (items is List)
          for (final item in items)
            if (item is Map) movementOf(decodeJsonObject(item)),
      ];

  static StatementPage statementOf(JsonMap json) {
    final next = _text(json['nextPageToken']);

    return StatementPage(
      movements: movementsOf(json['entries']),
      opening: amountAt(json, 'openingBalance') ?? 0,
      closing: amountAt(json, 'closingBalance') ?? 0,
      totalIn: amountAt(json, 'totalIn') ?? 0,
      totalOut: amountAt(json, 'totalOut') ?? 0,
      next: next.isEmpty ? null : next,
    );
  }

  /// A redeemed voucher: its amount and the wallet after it.
  static VoucherCredit voucherCreditOf(JsonMap json) => VoucherCredit(
        amount: amountAt(json, 'amount') ?? 0,
        balance: amountAt(objectAt(json, 'wallet') ?? const {}, 'balance') ?? 0,
        alreadyRedeemed: json['alreadyRedeemed'] == true,
      );

  /// What a top-up may be; the limits are whole amounts.
  static TopUpOptions topUpOptionsOf(JsonMap json) => TopUpOptions(
        min: amountAt(json, 'minAmount') ?? 0,
        max: amountAt(json, 'maxAmount') ?? 0,
        providers: [
          if (json['providers'] case final List<dynamic> names)
            for (final name in names)
              if (name is String) name,
        ],
      );

  /// A payment opened at the provider; an answer without its page is a bug.
  static TopUpStart topUpStartOf(JsonMap json) {
    final page = Uri.tryParse(_text(json['redirectUrl']));

    if (page == null || !page.isAbsolute) {
      throw const FormatException('the top-up has no payment page');
    }

    return TopUpStart(id: requiredText(json, 'topUpId'), page: page);
  }

  static TopUpStatus topUpStatusOf(JsonMap json) => switch (_text(json['status'])) {
        'succeeded' => TopUpStatus.succeeded,
        'failed' => TopUpStatus.failed,
        _ => TopUpStatus.pending,
      };

  /// The statement's query for [filter].
  static Map<String, dynamic> filterOf(MovementFilter filter) => switch (filter) {
        MovementFilter.all => const {},
        MovementFilter.moneyIn => const {'direction': 'in'},
        MovementFilter.moneyOut => const {'direction': 'out'},
        MovementFilter.tips => const {'types': 'TRANSACTION_TYPE_TIP'},
        MovementFilter.refunds => const {'types': 'TRANSACTION_TYPE_REFUND'},
      };

  static String _text(Object? value) => value is String ? value.trim() : '';
}
