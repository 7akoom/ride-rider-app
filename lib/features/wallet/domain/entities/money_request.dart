/// Where a money request stands. A pending one past its end is expired.
enum MoneyRequestStatus { pending, paid, declined, cancelled, expired }

/// How the rider stands to a request: they asked ([requester]), it is for them or
/// they paid it ([payer]), or they opened someone else's open request ([viewer]).
enum MoneyRequestRole { requester, payer, viewer }

/// The requests of one side: asked by the rider, or asked of them.
enum MoneyRequestSide { outgoing, incoming }

/// A rider asking for money, as the signed-in rider sees it. Names are short
/// ("Haidar K.") and may be empty when the server could not read them; a viewer sees
/// the requester's phone masked (+964750***4567) and not who paid.
final class MoneyRequest {
  const MoneyRequest({
    required this.id,
    required this.code,
    required this.role,
    required this.open,
    required this.amount,
    required this.status,
    required this.expiresAt,
    required this.createdAt,
    this.requesterName = '',
    this.requesterPhone = '',
    this.payerName = '',
    this.payerPhone = '',
    this.note = '',
    this.closedAt,
  });

  final String id;

  /// What the QR code and "pay with a code" carry: 10 letters and digits.
  final String code;
  final MoneyRequestRole role;

  /// Anyone with the code may pay it.
  final bool open;

  /// Whole currency units.
  final int amount;
  final MoneyRequestStatus status;
  final DateTime expiresAt;
  final DateTime createdAt;
  final String requesterName;
  final String requesterPhone;
  final String payerName;
  final String payerPhone;
  final String note;
  final DateTime? closedAt;

  bool get pending => status == MoneyRequestStatus.pending;

  /// The rider may pay it: pending, and not their own.
  bool get payable => pending && role != MoneyRequestRole.requester;

  /// Only the rider it is for may decline it.
  bool get declinable => pending && role == MoneyRequestRole.payer && !open;

  bool get cancellable => pending && role == MoneyRequestRole.requester;

  /// The code in two groups of five, easier to read out and type: "K7XMQ-2PQRX".
  String get displayCode => code.length == 10 ? '${code.substring(0, 5)}-${code.substring(5)}' : code;

  MoneyRequest copyWith({MoneyRequestStatus? status, DateTime? closedAt, String? payerName}) => MoneyRequest(
        id: id,
        code: code,
        role: role,
        open: open,
        amount: amount,
        status: status ?? this.status,
        expiresAt: expiresAt,
        createdAt: createdAt,
        requesterName: requesterName,
        requesterPhone: requesterPhone,
        payerName: payerName ?? this.payerName,
        payerPhone: payerPhone,
        note: note,
        closedAt: closedAt ?? this.closedAt,
      );
}

/// A request paid: the request as it stands now, the transfer's id and time, and
/// the payer's balance after it (null when the server did not say: a payment
/// repeated).
final class PaidRequest {
  const PaidRequest({required this.request, required this.transferId, required this.at, this.balance});

  final MoneyRequest request;
  final String transferId;
  final DateTime at;
  final int? balance;
}

/// Accepts a code as it is typed or read out: lower case, with spaces or a dash.
/// Null when it cannot be one (10 of the letters and digits codes use).
String? normalizeRequestCode(String typed) {
  final code = typed.toUpperCase().replaceAll(RegExp(r'[\s\-]'), '');

  return RegExp(r'^[A-HJ-KM-NP-Z2-9]{10}$').hasMatch(code) ? code : null;
}
