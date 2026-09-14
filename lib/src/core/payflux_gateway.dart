import 'package:flutter/widgets.dart';

import '../models/payflux_request.dart';
import 'payflux_result.dart';

/// The contract every payment provider implements.
///
/// To add a new gateway (PayU, Cashfree, Square, ...), implement this
/// interface and register an instance with [PayFlux.register] — nothing
/// else in the package needs to change.
abstract class PayFluxGateway {
  /// Short, lowercase identifier used to select this gateway, e.g.
  /// 'stripe', 'razorpay', 'paypal'.
  String get name;

  /// Called once via [PayFlux.configure] before the first [pay] call.
  /// Use this to set API/publishable keys and any SDK-level setup.
  Future<void> initialize(Map<String, dynamic> config);

  /// Starts the checkout flow and resolves once it's done — success,
  /// failure, or user cancellation all resolve normally; only
  /// unexpected errors should throw.
  ///
  /// [context] is required by gateways that present a screen or
  /// webview (e.g. PayPal); gateways that use a native bottom sheet
  /// (Stripe, Razorpay) can ignore it.
  Future<PayFluxResult> pay(PayFluxRequest request, {BuildContext? context});

  /// Release any resources (listeners, controllers). Called optionally
  /// by the app when a gateway is no longer needed.
  Future<void> dispose() async {}
}
