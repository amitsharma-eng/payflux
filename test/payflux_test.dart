import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payflux/payflux.dart';

/// A mock implementation of [PayFluxGateway] for testing purposes.
class MockGateway implements PayFluxGateway {
  @override
  final String name;
  
  /// Whether [initialize] has been called.
  bool initialized = false;
  
  /// Configuration passed during [initialize].
  Map<String, dynamic>? configPassed;
  
  /// The result that [pay] will return.
  PayFluxResult? mockResult;

  /// Creates a [MockGateway] with a given name.
  MockGateway(this.name);

  @override
  Future<void> initialize(Map<String, dynamic> config) async {
    initialized = true;
    configPassed = config;
  }

  @override
  Future<PayFluxResult> pay(PayFluxRequest request, {BuildContext? context}) async {
    if (mockResult != null) {
      return mockResult!;
    }
    return PayFluxResult(
      status: PayFluxStatus.success,
      gateway: name,
      transactionId: request.orderId,
    );
  }

  @override
  Future<void> dispose() async {
    initialized = false;
  }
}

void main() {
  setUp(() async {
    // Reset/clear gateways before each test.
    await PayFlux.instance.disposeAll();
  });

  tearDown(() async {
    await PayFlux.instance.disposeAll();
  });

  group('PayFlux Core Manager Tests', () {
    test('should register and list gateways correctly', () {
      final mockStripe = MockGateway('stripe');
      final mockRazorpay = MockGateway('razorpay');

      PayFlux.instance.register(mockStripe);
      expect(PayFlux.instance.registeredGateways, contains('stripe'));
      expect(PayFlux.instance.registeredGateways.length, 1);

      PayFlux.instance.registerAll([mockRazorpay]);
      expect(PayFlux.instance.registeredGateways, containsAll(['stripe', 'razorpay']));
      expect(PayFlux.instance.registeredGateways.length, 2);
    });

    test('should throw PayFluxException if paying via an unregistered gateway', () async {
      const request = PayFluxRequest(
        amount: 100.0,
        currency: 'USD',
        orderId: 'test_order_1',
      );

      expect(
        () => PayFlux.instance.pay(gateway: 'stripe', request: request),
        throwsA(isA<PayFluxException>().having(
          (e) => e.message,
          'message',
          contains('Gateway "stripe" is not registered'),
        )),
      );
    });

    test('should throw PayFluxException if paying via an unconfigured gateway', () async {
      final mockStripe = MockGateway('stripe');
      PayFlux.instance.register(mockStripe);

      const request = PayFluxRequest(
        amount: 100.0,
        currency: 'USD',
        orderId: 'test_order_1',
      );

      expect(
        () => PayFlux.instance.pay(gateway: 'stripe', request: request),
        throwsA(isA<PayFluxException>().having(
          (e) => e.message,
          'message',
          contains('Gateway "stripe" was not initialized'),
        )),
      );
    });

    test('should initialize and pay successfully via a registered and configured gateway', () async {
      final mockStripe = MockGateway('stripe');
      PayFlux.instance.register(mockStripe);

      await PayFlux.instance.configure('stripe', {'publishableKey': 'pk_test'});
      expect(mockStripe.initialized, true);
      expect(mockStripe.configPassed?['publishableKey'], 'pk_test');

      const request = PayFluxRequest(
        amount: 100.0,
        currency: 'USD',
        orderId: 'test_order_1',
      );

      final result = await PayFlux.instance.pay(gateway: 'stripe', request: request);
      expect(result.status, PayFluxStatus.success);
      expect(result.gateway, 'stripe');
      expect(result.transactionId, 'test_order_1');
      expect(result.isSuccess, true);
    });

    test('should clean up state on disposeAll', () async {
      final mockStripe = MockGateway('stripe');
      PayFlux.instance.register(mockStripe);
      await PayFlux.instance.configure('stripe', {});

      expect(PayFlux.instance.registeredGateways, contains('stripe'));

      await PayFlux.instance.disposeAll();
      expect(PayFlux.instance.registeredGateways.isEmpty, true);
    });
  });

  group('PayFlux Request and Result Model Tests', () {
    test('PayFluxRequest field mappings', () {
      const request = PayFluxRequest(
        amount: 50.50,
        currency: 'INR',
        orderId: 'order_abc',
        description: 'Test payment description',
        customerName: 'John Doe',
        customerEmail: 'john@example.com',
        customerContact: '+1234567890',
        metadata: {'custom_key': 'custom_value'},
      );

      expect(request.amount, 50.50);
      expect(request.currency, 'INR');
      expect(request.orderId, 'order_abc');
      expect(request.description, 'Test payment description');
      expect(request.customerName, 'John Doe');
      expect(request.customerEmail, 'john@example.com');
      expect(request.customerContact, '+1234567890');
      expect(request.metadata?['custom_key'], 'custom_value');
    });

    test('PayFluxResult toString format', () {
      const result = PayFluxResult(
        status: PayFluxStatus.failed,
        gateway: 'razorpay',
        transactionId: 'tx_123',
        errorMessage: 'Card declined',
      );

      expect(
        result.toString(),
        'PayFluxResult(gateway: razorpay, status: PayFluxStatus.failed, transactionId: tx_123, error: Card declined)',
      );
    });
  });
}
