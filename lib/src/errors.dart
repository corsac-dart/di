part of corsac_di;

/// DI error.
class DIError {
  final String message;

  DIError(this.message);

  @override
  String toString() => "DIError: $message";
}
