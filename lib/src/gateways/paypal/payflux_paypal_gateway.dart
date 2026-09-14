import 'package:flutter/material.dart';
import 'package:flutter_paypal_payment/flutter_paypal_payment.dart';

import '../../core/payflux_gateway.dart';
import '../../core/payflux_result.dart';
import '../../models/payflux_request.dart';
import '../../models/payflux_status.dart';

/// PayPal implementation of [PayFluxGateway], built on a webview
/// checkout screen. Unlike Stripe/Razorpay, this gateway pushes a new
/// route, so [context] is required when calling [pay].
class PayFluxPayPalGateway implements PayFluxGateway {
  /// Creates a [PayFluxPayPalGateway] instance.
  PayFluxPayPalGateway();
  late final String _clientId;
  late final String _secretKey;
  late final bool _sandboxMode;

  @override
  String get name => 'paypal';

  @override
  Future<void> initialize(Map<String, dynamic> config) async {
    final clientId = config['clientId'] as String?;
    final secretKey = config['secretKey'] as String?;
    if (clientId == null || clientId.isEmpty || secretKey == null || secretKey.isEmpty) {
      throw ArgumentError('PayPal requires "clientId" and "secretKey" in config');
    }
    _clientId = clientId;
    _secretKey = secretKey;
    _sandboxMode = config['sandboxMode'] as bool? ?? true;
  }

  @override
  Future<PayFluxResult> pay(PayFluxRequest request, {BuildContext? context}) async {
    if (context == null) {
      return PayFluxResult(
        status: PayFluxStatus.failed,
        gateway: name,
        errorMessage:
            'PayPal requires a BuildContext — pass context: to PayFlux.instance.pay(...)',
      );
    }

    PayFluxResult? result;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (routeContext) => PaypalCheckoutView(
          sandboxMode: _sandboxMode,
          clientId: _clientId,
          secretKey: _secretKey,
          transactions: [
            {
              'amount': {
                'total': request.amount.toStringAsFixed(2),
                'currency': request.currency,
                'details': {
                  'subtotal': request.amount.toStringAsFixed(2),
                  'shipping': '0',
                  'shipping_discount': 0,
                },
              },
              'description': request.description,
              'item_list': const {'items': []},
            },
          ],
          note: 'PayFlux transaction ${request.orderId}',
          onSuccess: (Map params) async {
            result = PayFluxResult(
              status: PayFluxStatus.success,
              gateway: name,
              transactionId: params['data']?['id']?.toString() ?? request.orderId,
              rawResponse: Map<String, dynamic>.from(params),
            );
            Navigator.of(routeContext).pop();
          },
          onError: (error) {
            result = PayFluxResult(
              status: PayFluxStatus.failed,
              gateway: name,
              errorMessage: error.toString(),
            );
            Navigator.of(routeContext).pop();
          },
          onCancel: () {
            result = PayFluxResult(status: PayFluxStatus.cancelled, gateway: name);
            Navigator.of(routeContext).pop();
          },
        ),
      ),
    );

    return result ??
        PayFluxResult(
          status: PayFluxStatus.cancelled,
          gateway: name,
          errorMessage: 'Checkout closed without a result',
        );
  }

  @override
  Future<void> dispose() async {}
}
