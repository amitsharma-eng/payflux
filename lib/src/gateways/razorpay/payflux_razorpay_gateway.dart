import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../core/payflux_gateway.dart';
import '../../core/payflux_result.dart';
import '../../models/payflux_request.dart';
import '../../models/payflux_status.dart';

/// Razorpay implementation of [PayFluxGateway], built on the official
/// `razorpay_flutter` checkout widget.
class PayFluxRazorpayGateway implements PayFluxGateway {
  /// Creates a [PayFluxRazorpayGateway] instance.
  PayFluxRazorpayGateway();
  late final Razorpay _razorpay;
  late final String _key;
  Completer<PayFluxResult>? _completer;

  @override
  String get name => 'razorpay';

  @override
  Future<void> initialize(Map<String, dynamic> config) async {
    final key = config['key'] as String?;
    if (key == null || key.isEmpty) {
      throw ArgumentError('Razorpay requires "key" in config');
    }
    _key = key;
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  @override
  Future<PayFluxResult> pay(PayFluxRequest request, {BuildContext? context}) {
    _completer = Completer<PayFluxResult>();

    final options = <String, dynamic>{
      'key': _key,
      'amount': (request.amount * 100).round(), // Razorpay expects paise.
      'currency': request.currency,
      'name': request.customerName ?? 'PayFlux',
      'description': request.description,
      'order_id': request.orderId,
      'prefill': {
        'contact': request.customerContact ?? '',
        'email': request.customerEmail ?? '',
      },
      if (request.metadata != null) 'notes': request.metadata,
    };

    _razorpay.open(options);
    return _completer!.future;
  }

  void _onSuccess(PaymentSuccessResponse response) {
    _completer?.complete(PayFluxResult(
      status: PayFluxStatus.success,
      gateway: name,
      transactionId: response.paymentId,
      rawResponse: {
        'orderId': response.orderId,
        'signature': response.signature,
      },
    ));
  }

  void _onError(PaymentFailureResponse response) {
    _completer?.complete(PayFluxResult(
      status: response.code == Razorpay.PAYMENT_CANCELLED
          ? PayFluxStatus.cancelled
          : PayFluxStatus.failed,
      gateway: name,
      errorMessage: response.message,
    ));
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    _completer?.complete(PayFluxResult(
      status: PayFluxStatus.pending,
      gateway: name,
      errorMessage: 'Redirected to external wallet: ${response.walletName}',
    ));
  }

  @override
  Future<void> dispose() async {
    _razorpay.clear();
  }
}
