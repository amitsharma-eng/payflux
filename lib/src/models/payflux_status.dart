/// Normalized outcome of a payment attempt, mapped consistently
/// across every gateway so calling code never has to branch on
/// gateway-specific status strings.
enum PayFluxStatus {
  /// The payment was successfully completed.
  success,

  /// The payment failed due to an error (e.g. declined card).
  failed,

  /// The payment was cancelled by the user.
  cancelled,

  /// The payment is pending (e.g. waiting for external wallet).
  pending,
}
