import '../../../core/error/failure.dart';
import '../../../core/error/guard.dart';
import '../../../core/error/result.dart';
import '../../../core/network/json.dart';
import '../../../core/security/session_storage.dart';
import '../domain/entities/fare_quote.dart';
import '../domain/entities/payment_method.dart';
import '../domain/entities/spot.dart';
import '../domain/entities/trip_draft.dart';
import '../domain/repositories/rides_repository.dart';
import 'fare_quote_json.dart';
import 'rides_api.dart';

final class RidesRepositoryImpl implements RidesRepository {
  RidesRepositoryImpl(this._api);

  final RidesApi _api;

  /// The trip-service's limit for an address.
  static const int maxAddressLength = 300;

  @override
  Future<Result<FareQuotes>> quote(TripDraft draft, {String? couponCode}) => guard(() async {
        final json = await _api.quotes({
          'riderId': await _riderId(),
          'pickup': draft.pickup!.point.toJson(),
          'dropoff': draft.destination!.point.toJson(),
          if (draft.stops.isNotEmpty) 'stops': [for (final s in draft.stops) s.point.toJson()],
          if (couponCode != null) 'couponCode': couponCode,
        });

        return FareQuoteJson.quotesOf(json);
      });

  @override
  Future<Result<int>> walletBalance() => guard(() async {
        final json = await _api.wallet(await _riderId());

        return amountAt(objectAt(json, 'wallet') ?? const {}, 'balance') ?? 0;
      });

  @override
  Future<Result<String>> request({
    required TripDraft draft,
    required FareQuote quote,
    required PaymentMethod payment,
  }) =>
      guard(() async {
        final json = await _api.requestTrip({
          'riderId': await _riderId(),
          'pickup': draft.pickup!.point.toJson(),
          'dropoff': draft.destination!.point.toJson(),
          'pickupAddress': addressOf(draft.pickup!),
          'dropoffAddress': addressOf(draft.destination!),
          'vehicleClass': quote.vehicleClass,
          'paymentMethod': payment.name,
          'quoteId': quote.id,
          if (draft.stops.isNotEmpty)
            'stops': [
              for (final stop in draft.stops)
                {'coordinates': stop.point.toJson(), 'address': addressOf(stop)},
            ],
        });

        return requiredText(objectAt(json, 'trip') ?? const {}, 'id');
      });

  /// The place as the captain reads it: its name and address, within the limit.
  static String addressOf(Spot spot) {
    final text = [spot.title, spot.detail]
        .whereType<String>()
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .join(', ');
    final runes = text.runes;

    return runes.length <= maxAddressLength
        ? text
        : String.fromCharCodes(runes.take(maxAddressLength));
  }

  static Future<String> _riderId() async {
    final riderId = await SessionStorage.readRiderId();

    if (riderId == null || riderId.isEmpty) {
      throw const SessionExpiredFailure();
    }

    return riderId;
  }
}
