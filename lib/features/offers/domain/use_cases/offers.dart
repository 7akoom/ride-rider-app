import '../../../../core/error/result.dart';
import '../entities/offer.dart';
import '../repositories/offers_repository.dart';

final class LoadOffers {
  const LoadOffers(this.offers);

  final OffersRepository offers;

  Future<Result<RiderOffers>> call() => offers.offers();
}

/// Checks a typed code; one that cannot be a code is not asked about.
final class CheckCode {
  const CheckCode(this.offers);

  final OffersRepository offers;

  Future<Result<CodeCheckResult>> call(String typed) async {
    final code = normalizeOfferCode(typed);

    if (code == null) {
      return const Ok(CodeCheckResult(CodeCheck.notFound));
    }

    return offers.check(code);
  }
}

/// The code for the rider's next ride: the price applies it by itself.
final class KeepCode {
  const KeepCode(this.offers);

  final OffersRepository offers;

  Future<String?> kept() => offers.keptCode();

  Future<void> keep(String code) async {
    final normalized = normalizeOfferCode(code);

    if (normalized != null) {
      await offers.keep(normalized);
    }
  }

  Future<void> forget() => offers.forget();
}
