/// Describes a recoverable broker persistence failure for presentation layers.
class BrokerRepositoryFailure {
  /// Creates a failure with a user-facing [message] and safe [details].
  const BrokerRepositoryFailure({required this.message, required this.details});

  final String message;
  final String details;
}
