# PayFlux

One Flutter API for many payment gateways. Register the gateways you need,
configure them once, and call a single `pay()` — swapping or adding a
provider later means writing one new class, not rewriting your checkout.

```dart
final result = await PayFlux.instance.pay(
  gateway: 'razorpay',
  request: PayFluxRequest(amount: 499, currency: 'INR', orderId: 'order_1'),
);

if (result.isSuccess) {
  print('Paid! txn: ${result.transactionId}');
}
```

## Why

Every payment SDK has its own shape: Stripe wants a client secret from
your server, Razorpay fires callback events, PayPal wants a screen to push.
PayFlux hides that behind one interface (`PayFluxGateway`) and one result
type (`PayFluxResult`), so your UI code never branches on which provider
is active.

## Included gateways (v0.1.0)

| Gateway  | Package               | Notes                                   |
|----------|------------------------|------------------------------------------|
| Stripe   | `flutter_stripe`       | Needs a backend endpoint for PaymentIntents |
| Razorpay | `razorpay_flutter`     | Native checkout, India-focused          |
| PayPal   | `flutter_paypal_payment` | Webview checkout, needs `BuildContext` |

Platforms: **Android & iOS**. Web/Desktop support is on the roadmap — see
[Architecture](#architecture) for why it's a small lift from here.

## Install

```yaml
dependencies:
  payflux:
    path: ../payflux   # or a git/pub.dev reference once published
```

Then complete each gateway's native setup:

- **Stripe**: no extra native config beyond `flutter_stripe`'s own iOS/Android
  setup (Info.plist URL scheme for redirects, minimum SDK versions).
- **Razorpay**: add your Razorpay key; Android may require enabling
  `android:exported` handling per `razorpay_flutter`'s docs.
- **PayPal**: sandbox vs live mode is a boolean in `configure()` — no native
  files to touch.

Check each plugin's own README on pub.dev for the current native setup
steps, since these change independently of PayFlux.

## Usage

```dart
void main() {
  PayFlux.instance.registerAll([
    PayFluxStripeGateway(createPaymentIntent: myBackend.createIntent),
    PayFluxRazorpayGateway(),
    PayFluxPayPalGateway(),
  ]);
  runApp(const MyApp());
}

// Later, once — usually at app start or right before checkout:
await PayFlux.instance.configure('razorpay', {'key': 'rzp_test_...'});

// Then, per payment:
final result = await PayFlux.instance.pay(
  gateway: 'razorpay',
  request: PayFluxRequest(
    amount: 499,
    currency: 'INR',
    orderId: 'order_123',
    customerEmail: 'jane@example.com',
  ),
  context: context, // required for PayPal, ignored by Stripe/Razorpay
);

switch (result.status) {
  case PayFluxStatus.success:
    // verify result.transactionId server-side, then fulfil the order
    break;
  case PayFluxStatus.cancelled:
    // user backed out — no error to show
    break;
  case PayFluxStatus.failed:
    // show result.errorMessage
    break;
  case PayFluxStatus.pending:
    // e.g. redirected to an external wallet — poll or webhook for the final state
    break;
}
```

Full runnable version in [`example/`](example/lib/main.dart).

## Architecture

```
PayFlux (facade/registry, singleton)
   └── PayFluxGateway (abstract interface)
          ├── PayFluxStripeGateway
          ├── PayFluxRazorpayGateway
          ├── PayFluxPayPalGateway
          └── ...your own
```

`PayFlux.instance` holds a registry of `name -> PayFluxGateway`. It doesn't
know anything about Stripe or Razorpay specifically — it just calls
`initialize()` then `pay()` on whichever one you named.

### Adding a new gateway

```dart
class PayFluxSquareGateway implements PayFluxGateway {
  @override
  String get name => 'square';

  @override
  Future<void> initialize(Map<String, dynamic> config) async { ... }

  @override
  Future<PayFluxResult> pay(PayFluxRequest request, {BuildContext? context}) async {
    // call the Square SDK, map its result onto PayFluxResult
  }

  @override
  Future<void> dispose() async {}
}
```

Register it — `PayFlux.instance.register(PayFluxSquareGateway())` — and it's
usable through the exact same `pay()` call as every other gateway.

### Roadmap

- Web support (Stripe.js / PayPal JS SDK behind the same interface)
- PayU, Cashfree, Paytm gateways
- A `PayFluxResult` → receipt/webhook verification helper
- Split into federated packages (`payflux_core`, `payflux_stripe`, ...) so
  apps only pull in the SDKs they actually use

## Security notes

- Never put Stripe **secret** keys or PayPal **secret** keys directly in a
  shipped app in production — `secretKey` in the PayPal example config and
  `createPaymentIntent` in Stripe's are both meant to go through *your*
  backend.
- Always verify the final payment status server-side (via webhook or a
  verify-signature endpoint) before fulfilling an order — never trust the
  client-side `PayFluxResult` alone for that decision.

## License

MIT — see [LICENSE](LICENSE).
