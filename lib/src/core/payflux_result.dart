import '../models/payflux_status.dart';

/// The outcome of a [PayFluxGateway.pay] call, normalized so calling
/// code can handle every gateway identically.
class PayFluxResult {
  /// Creates a [PayFluxResult] with the given details.
  const PayFluxResult({
    required this.status,
    required this.gateway,
    this.transactionId,
    this.errorMessage,
    this.rawResponse,
  });

  /// The status of the payment attempt.
  final PayFluxStatus status;

  /// Name of the gateway that produced this result, e.g. 'stripe'.
  final String gateway;

  /// Gateway-issued transaction/payment id, when available.
  final String? transactionId;

  /// Human-readable error message if the status is [PayFluxStatus.failed].
  final String? errorMessage;

  /// The raw, gateway-specific payload, kept for debugging or
  /// server-side verification. Don't rely on its shape across gateways.
  final Map<String, dynamic>? rawResponse;

  /// Helper to check if the status is [PayFluxStatus.success].
  bool get isSuccess => status == PayFluxStatus.success;

  @override
  String toString() =>
      'PayFluxResult(gateway: $gateway, status: $status, '
      'transactionId: $transactionId, error: $errorMessage)';
}
