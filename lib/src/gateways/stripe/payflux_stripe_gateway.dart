import 'package:flutter/widgets.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;

import '../../core/payflux_gateway.dart';
import '../../core/payflux_result.dart';
import '../../models/payflux_request.dart';
import '../../models/payflux_status.dart';

/// Stripe implementation of [PayFluxGateway], built on Stripe's
/// PaymentSheet.
///
/// Stripe's secret key must never live in the app. You supply
/// [createPaymentIntent], a callback that hits YOUR backend, which
/// creates the PaymentIntent server-side and returns its `client_secret`.
class PayFluxStripeGateway implements PayFluxGateway {
  /// Creates a [PayFluxStripeGateway] instance.
  ///
  /// Requires [createPaymentIntent], a callback that calls your backend
  /// to generate a Stripe PaymentIntent client secret.
  PayFluxStripeGateway({required this.createPaymentIntent});

  /// Calls your backend to create a PaymentIntent for [request] and
  /// returns its client secret.
  final Future<String> Function(PayFluxRequest request) createPaymentIntent;

  @override
  String get name => 'stripe';

  @override
  Future<void> initialize(Map<String, dynamic> config) async {
    final publishableKey = config['publishableKey'] as String?;
    if (publishableKey == null || publishableKey.isEmpty) {
      throw ArgumentError('Stripe requires "publishableKey" in config');
    }
    stripe.Stripe.publishableKey = publishableKey;
    final merchantId = config['merchantIdentifier'] as String?;
    if (merchantId != null) {
      stripe.Stripe.merchantIdentifier = merchantId;
    }
    await stripe.Stripe.instance.applySettings();
  }

  @override
  Future<PayFluxResult> pay(PayFluxRequest request, {BuildContext? context}) async {
    try {
      final clientSecret = await createPaymentIntent(request);

      await stripe.Stripe.instance.initPaymentSheet(
        paymentSheetParameters: stripe.SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: request.customerName ?? 'PayFlux Merchant',
        ),
      );

      await stripe.Stripe.instance.presentPaymentSheet();

      return PayFluxResult(
        status: PayFluxStatus.success,
        gateway: name,
        transactionId: request.orderId,
      );
    } on stripe.StripeException catch (e) {
      final cancelled = e.error.code == stripe.FailureCode.Canceled;
      return PayFluxResult(
        status: cancelled ? PayFluxStatus.cancelled : PayFluxStatus.failed,
        gateway: name,
        errorMessage: e.error.localizedMessage ?? e.error.message,
      );
    } catch (e) {
      return PayFluxResult(
        status: PayFluxStatus.failed,
        gateway: name,
        errorMessage: e.toString(),
      );
    }
  }

  @override
  Future<void> dispose() async {}
}
