/// Single exception thrown by every SDK call on non-2xx responses and on
/// network/timeout failures.
///
/// Unknown server codes pass through as-is on [code] so callers can handle new
/// codes without waiting for an SDK update.
class CryptohopperException implements Exception {
  /// Error code from the shared SDK taxonomy (see [knownCodes]) or a raw
  /// server-provided string when the server returns something unrecognised.
  final String code;

  /// Human-readable error description, taken verbatim from the server when
  /// available.
  final String message;

  /// HTTP status code. Zero for network/timeout failures where no response
  /// was received.
  final int status;

  /// Cryptohopper's numeric `code` field from the JSON error envelope, when
  /// present. Null otherwise.
  final int? serverCode;

  /// Caller IP as the server saw it, extracted from the error envelope's
  /// `ip_address` field when the server includes it.
  final String? ipAddress;

  /// Milliseconds to wait before retrying, parsed from the `Retry-After`
  /// header on a 429. Null on any other error.
  final int? retryAfterMs;

  const CryptohopperException({
    required this.code,
    required this.message,
    required this.status,
    this.serverCode,
    this.ipAddress,
    this.retryAfterMs,
  });

  /// Stable error codes shared across every official Cryptohopper SDK.
  static const List<String> knownCodes = [
    'VALIDATION_ERROR',
    'UNAUTHORIZED',
    'FORBIDDEN',
    'NOT_FOUND',
    'CONFLICT',
    'RATE_LIMITED',
    'SERVER_ERROR',
    'SERVICE_UNAVAILABLE',
    'DEVICE_UNAUTHORIZED',
    'NETWORK_ERROR',
    'TIMEOUT',
    'UNKNOWN',
  ];

  @override
  String toString() {
    final extras = <String>[];
    if (serverCode != null) extras.add('server_code=$serverCode');
    if (ipAddress != null) extras.add('ip=$ipAddress');
    if (retryAfterMs != null) extras.add('retry_after_ms=$retryAfterMs');
    final extra = extras.isEmpty ? '' : ' (${extras.join(', ')})';
    return 'CryptohopperException[$code/$status]$extra: $message';
  }
}
