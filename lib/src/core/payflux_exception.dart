/// Thrown for PayFlux-level errors: an unregistered or unconfigured
/// gateway, or an unexpected failure while delegating to one.
///
/// Ordinary declined/cancelled payments are NOT exceptions — they come
/// back as a [PayFluxResult] with [PayFluxStatus.failed] or
/// [PayFluxStatus.cancelled] instead, so you don't need try/catch for
/// the normal decline flow.
class PayFluxException implements Exception {
  /// Creates a new [PayFluxException] with the given [message].
  PayFluxException(this.message, {this.gateway, this.cause});

  /// The error message.
  final String message;

  /// The name of the gateway where the error occurred, if applicable.
  final String? gateway;

  /// The underlying cause of the exception, if any.
  final Object? cause;

  @override
  String toString() =>
      'PayFluxException${gateway != null ? ' [$gateway]' : ''}: $message'
      '${cause != null ? ' (cause: $cause)' : ''}';
}
