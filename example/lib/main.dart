import 'package:flutter/material.dart';
import 'package:payflux/payflux.dart';

void main() {
  PayFlux.instance.registerAll([
    PayFluxStripeGateway(
      createPaymentIntent: (request) async {
        // Call YOUR backend here — never create PaymentIntents client-side.
        // return await MyBackend.createStripeIntent(request);
        throw UnimplementedError('Wire this up to your backend');
      },
    ),
    PayFluxRazorpayGateway(),
    PayFluxPayPalGateway(),
  ]);

  runApp(const PayFluxExampleApp());
}

/// The example app widget.
class PayFluxExampleApp extends StatelessWidget {
  /// Creates the example app.
  const PayFluxExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'PayFlux Example',
      home: CheckoutPage(),
    );
  }
}

/// The main checkout page for the example app.
class CheckoutPage extends StatefulWidget {
  /// Creates the checkout page.
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String _status = 'Ready';
  bool _configured = false;

  Future<void> _configureGateways() async {
    if (_configured) return;
    await PayFlux.instance.configure('razorpay', {
      'key': 'rzp_test_XXXXXXXXXXXX',
    });
    await PayFlux.instance.configure('paypal', {
      'clientId': 'YOUR_PAYPAL_CLIENT_ID',
      'secretKey': 'YOUR_PAYPAL_SECRET',
      'sandboxMode': true,
    });
    await PayFlux.instance.configure('stripe', {
      'publishableKey': 'pk_test_XXXXXXXXXXXX',
    });
    _configured = true;
  }

  Future<void> _pay(String gateway) async {
    if (!mounted) return;
    setState(() => _status = 'Processing via $gateway…');
    await _configureGateways();

    if (!mounted) return;
    final request = PayFluxRequest(
      amount: 499.00,
      currency: gateway == 'razorpay' ? 'INR' : 'USD',
      orderId: 'order_${DateTime.now().millisecondsSinceEpoch}',
      description: 'PayFlux demo purchase',
      customerName: 'Jane Doe',
      customerEmail: 'jane@example.com',
    );

    final result = await PayFlux.instance.pay(
      gateway: gateway,
      request: request,
      context: context,
    );

    if (!mounted) return;
    setState(() => _status = result.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PayFlux Example')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () => _pay('stripe'),
                child: const Text('Pay with Stripe'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => _pay('razorpay'),
                child: const Text('Pay with Razorpay'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => _pay('paypal'),
                child: const Text('Pay with PayPal'),
              ),
              const SizedBox(height: 24),
              Text(_status, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
