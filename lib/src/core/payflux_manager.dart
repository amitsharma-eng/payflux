import 'package:flutter/widgets.dart';

import '../models/payflux_request.dart';
import 'payflux_exception.dart';
import 'payflux_gateway.dart';
import 'payflux_result.dart';

/// Single entry point for the whole package.
///
/// ```dart
/// PayFlux.instance.registerAll([
///   PayFluxStripeGateway(createPaymentIntent: myBackend.createIntent),
///   PayFluxRazorpayGateway(),
/// ]);
///
/// await PayFlux.instance.configure('razorpay', {'key': 'rzp_test_...'});
///
/// final result = await PayFlux.instance.pay(
///   gateway: 'razorpay',
///   request: PayFluxRequest(amount: 499, currency: 'INR', orderId: 'o1'),
/// );
/// ```
class PayFlux {
  PayFlux._internal();

  /// The singleton instance of [PayFlux].
  static final PayFlux instance = PayFlux._internal();

  final Map<String, PayFluxGateway> _gateways = {};
  final Set<String> _initialized = {};

  /// Registers a single gateway implementation under its [PayFluxGateway.name].
  void register(PayFluxGateway gateway) {
    _gateways[gateway.name] = gateway;
  }

  /// Convenience for registering several gateways at once.
  void registerAll(List<PayFluxGateway> gateways) {
    for (final gateway in gateways) {
      register(gateway);
    }
  }

  /// Runs [PayFluxGateway.initialize] for the named gateway. Must be
  /// called before [pay] for that gateway.
  Future<void> configure(String gatewayName, Map<String, dynamic> config) async {
    final gateway = _requireGateway(gatewayName);
    await gateway.initialize(config);
    _initialized.add(gatewayName);
  }

  /// Runs checkout through the named, already-configured gateway.
  Future<PayFluxResult> pay({
    required String gateway,
    required PayFluxRequest request,
    BuildContext? context,
  }) async {
    final g = _requireGateway(gateway);
    if (!_initialized.contains(gateway)) {
      throw PayFluxException(
        'Gateway "$gateway" was not initialized. '
        'Call PayFlux.instance.configure("$gateway", {...}) first.',
        gateway: gateway,
      );
    }
    try {
      return await g.pay(request, context: context);
    } on PayFluxException {
      rethrow;
    } catch (e) {
      throw PayFluxException('Unexpected error during payment', gateway: gateway, cause: e);
    }
  }

  /// Disposes and unregisters every gateway. Useful on app teardown.
  Future<void> disposeAll() async {
    for (final gateway in _gateways.values) {
      await gateway.dispose();
    }
    _gateways.clear();
    _initialized.clear();
  }

  /// Returns a list of names for all currently registered gateways.
  List<String> get registeredGateways => _gateways.keys.toList(growable: false);

  PayFluxGateway _requireGateway(String name) {
    final gateway = _gateways[name];
    if (gateway == null) {
      throw PayFluxException(
        'Gateway "$name" is not registered. Call PayFlux.instance.register(...) first. '
        'Currently registered: $registeredGateways',
      );
    }
    return gateway;
  }
}
