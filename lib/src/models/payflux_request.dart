/// A gateway-agnostic description of a payment to be charged.
///
/// Each [PayFluxGateway] implementation maps this onto whatever shape
/// its underlying SDK expects.
class PayFluxRequest {
  /// Creates a [PayFluxRequest] describing a payment attempt.
  const PayFluxRequest({
    required this.amount,
    required this.currency,
    required this.orderId,
    this.description = '',
    this.customerName,
    this.customerEmail,
    this.customerContact,
    this.metadata,
  });

  /// Amount in the major currency unit (e.g. 499.00 for ₹499.00),
  /// NOT in the smallest unit. Individual gateways convert as needed.
  final double amount;

  /// ISO 4217 currency code, e.g. 'INR', 'USD', 'EUR'.
  final String currency;

  /// Your own order/reference id, used for reconciliation.
  final String orderId;

  /// Optional description of the transaction.
  final String description;

  /// Optional name of the customer.
  final String? customerName;

  /// Optional email address of the customer.
  final String? customerEmail;

  /// Optional contact phone number of the customer.
  final String? customerContact;

  /// Arbitrary extra data passed through to gateways that support it
  /// (e.g. Razorpay 'notes').
  final Map<String, dynamic>? metadata;
}
