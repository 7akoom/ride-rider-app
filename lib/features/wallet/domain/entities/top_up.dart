/// How a top-up through a payment provider stands. The server asks the provider
/// itself, so this is the provider's word, never the app's guess.
enum TopUpStatus { pending, succeeded, failed }

/// Why an amount cannot be topped up.
enum TopUpAmountProblem { tooSmall, tooBig }

/// What a top-up may be in this deployment: whole amounts from [min] to [max],
/// through [providers]. Without ZainCash, money reaches the wallet by vouchers only.
final class TopUpOptions {
  const TopUpOptions({required this.min, required this.max, this.providers = const []});

  final int min;
  final int max;
  final List<String> providers;

  static const String zainCash = 'zaincash';

  /// The app offers "top up the wallet".
  bool get available => providers.contains(zainCash);

  /// What is wrong with [amount]; null when it can be topped up.
  TopUpAmountProblem? problemOf(int amount) {
    if (amount < min) {
      return TopUpAmountProblem.tooSmall;
    }

    if (amount > max) {
      return TopUpAmountProblem.tooBig;
    }

    return null;
  }
}

/// A payment opened at the provider: the top-up's id and the page to pay on.
final class TopUpStart {
  const TopUpStart({required this.id, required this.page});

  final String id;
  final Uri page;
}
