import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/features/wallet/presentation/payment_page_screen.dart';

void main() {
  const api = 'https://ride-api.example.com';

  bool returns(String url) => isPaymentReturnPage(Uri.parse(url), apiBaseUrl: api);

  test('our return pages close the payment page', () {
    expect(returns('https://ride-api.example.com/pay/done/?token=abc'), isTrue);
    expect(returns('https://ride-api.example.com/pay/failed/?token=abc'), isTrue);
    expect(returns('https://ride-api.example.com/pay/done'), isTrue);
    expect(returns('https://RIDE-API.example.com/pay/failed'), isTrue);
  });

  test('other pages stay open', () {
    // The provider's own pages, even with the same path.
    expect(returns('https://pg-api-uat.zaincash.iq/pay/done/'), isFalse);
    // Another page on our domain.
    expect(returns('https://ride-api.example.com/pay/'), isFalse);
    expect(returns('https://ride-api.example.com/pay/done/more'), isFalse);
    // A look-alike domain.
    expect(returns('https://ride-api.example.com.evil.iq/pay/done/'), isFalse);
  });
}
