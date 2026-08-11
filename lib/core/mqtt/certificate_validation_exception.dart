/// Reports a certificate selection or TLS configuration that cannot be used.
class CertificateValidationException implements Exception {
  /// Creates a validation exception with a safe user-visible [message].
  const CertificateValidationException(this.message);

  final String message;

  /// Returns the safe validation message.
  @override
  String toString() => message;
}
