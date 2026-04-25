# Error Handling

Every non-2xx response and every transport failure throws `CryptohopperException`. Same shape as the Node/Python/Go/Ruby/Rust/PHP/Swift SDKs but laid out idiomatically as a Dart class with public final fields.

```dart
try {
  await client.hoppers.get('999999');
} on CryptohopperException catch (e) {
  e.code;          // 'NOT_FOUND'
  e.status;        // 404
  e.message;       // human-readable, from the server
  e.serverCode;    // int? — numeric Cryptohopper code (or null)
  e.ipAddress;     // String? — server-reported caller IP (or null)
  e.retryAfterMs;  // int? — only set on 429
}
```

`CryptohopperException` implements `Exception` (not `Error`). A bare `try/catch` will catch it; `try/on Exception` will too. Prefer the typed `on CryptohopperException` clause — it makes intent clear and lets you handle SDK errors separately from your own.

## Error code catalog

| `code` | HTTP | When you'll see it | Recover by |
|---|---|---|---|
| `VALIDATION_ERROR` | 400, 422 | Missing or malformed parameter | Fix the request; the message says which parameter |
| `UNAUTHORIZED` | 401 | Token missing, wrong, or revoked | Re-auth |
| `DEVICE_UNAUTHORIZED` | 402 | Internal Cryptohopper device-auth flow rejected you | Shouldn't happen via the public API; contact support |
| `FORBIDDEN` | 403 | Scope missing, or IP not allowlisted | Check `e.ipAddress`; add to allowlist or grant the scope |
| `NOT_FOUND` | 404 | Resource or endpoint doesn't exist | Check the ID; check you're using the latest SDK |
| `CONFLICT` | 409 | Resource is in a conflicting state | Cancel the existing job or wait |
| `RATE_LIMITED` | 429 | Bucket exhausted | The SDK auto-retries; see [Rate Limits](Rate-Limits.md) |
| `SERVER_ERROR` | 500–502, 504 | Cryptohopper's end | Retry with back-off |
| `SERVICE_UNAVAILABLE` | 503 | Planned maintenance or downstream outage | Respect `retryAfterMs`; retry |
| `NETWORK_ERROR` | — | DNS failure, TCP reset, TLS handshake failure | Retry; check your network |
| `TIMEOUT` | — | Hit the client-side `timeout:` (covers connect AND body read since iter-12) | Retry; bump timeout if legitimately slow |
| `UNKNOWN` | any | Anything else the SDK didn't recognise | Inspect `e.status` and `e.message` |

These strings are stable across SDK versions and are also exposed as `CryptohopperException.knownCodes` — compare with `==`, never substring-match.

## Discriminating with `switch`

```dart
catch (e) {
  if (e is CryptohopperException) {
    switch (e.code) {
      case 'UNAUTHORIZED':
      case 'FORBIDDEN':
      case 'DEVICE_UNAUTHORIZED':
        await handleAuth(e);
        break;
      case 'VALIDATION_ERROR':
        log.warning('bad request: ${e.message}');
        break;
      case 'NOT_FOUND':
        // expected
        break;
      case 'CONFLICT':
        await retryOrSkip();
        break;
      case 'RATE_LIMITED':
        // SDK already retried; back off harder
        await Future.delayed(Duration(milliseconds: e.retryAfterMs ?? 5_000));
        break;
      case 'SERVER_ERROR':
      case 'SERVICE_UNAVAILABLE':
        scheduleRetry();
        break;
      case 'NETWORK_ERROR':
      case 'TIMEOUT':
        retryNow();
        break;
      default:
        // Unknown / new server-side codes: log and re-throw.
        rethrow;
    }
  } else {
    rethrow;
  }
}
```

Future-proof your handler with a `default` arm — the server can return new codes the SDK predates, and they pass through as raw strings on `e.code`.

## Pattern matching (Dart 3.0+)

Dart 3.0 introduced pattern matching, which makes the above cleaner:

```dart
on CryptohopperException catch (e) {
  switch (e) {
    case CryptohopperException(code: 'UNAUTHORIZED' || 'FORBIDDEN'):
      await refreshToken();
    case CryptohopperException(code: 'RATE_LIMITED', retryAfterMs: final ms?):
      await Future.delayed(Duration(milliseconds: ms));
    case CryptohopperException(code: 'NETWORK_ERROR' || 'TIMEOUT'):
      retryNow();
    case CryptohopperException(code: final code) when code.startsWith('SERVER'):
      scheduleRetry();
    default:
      rethrow;
  }
}
```

The `final ms?` binding pattern lets you destructure non-null `retryAfterMs` directly into a local.

## Distinguishing TIMEOUT from NETWORK_ERROR

A `TIMEOUT` is recoverable by **raising your `timeout:` value** and retrying; a `NETWORK_ERROR` typically requires **fixing your network** (DNS, firewall, no signal). Treat them differently:

```dart
on CryptohopperException catch (e) {
  if (e.code == 'TIMEOUT') {
    log.info('Cryptohopper slow — retrying with longer deadline');
    final patient = CryptohopperClient(apiKey: token, timeout: const Duration(minutes: 2));
    return await patient.user.get();
  }
  if (e.code == 'NETWORK_ERROR') {
    log.warning('Network problem — surfacing to user');
    throw NetworkUnavailableException(e.message);
  }
  rethrow;
}
```

## A robust retry wrapper

```dart
import 'dart:math';
import 'package:cryptohopper/cryptohopper.dart';

const _transient = {'SERVER_ERROR', 'SERVICE_UNAVAILABLE', 'NETWORK_ERROR', 'TIMEOUT'};

Future<T> withRetry<T>(
  Future<T> Function() fn, {
  int maxAttempts = 5,
  int baseMs = 500,
}) async {
  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await fn();
    } on CryptohopperException catch (e) {
      if (!_transient.contains(e.code) || attempt == maxAttempts) rethrow;
      final wait = e.retryAfterMs ?? baseMs * pow(2, attempt - 1).toInt();
      await Future.delayed(Duration(milliseconds: wait));
    }
  }
  throw StateError('unreachable');
}

await withRetry(() => client.hoppers.list());
```

Don't include `RATE_LIMITED` in `_transient` — the SDK already retries 429s internally. Wrapping it here would multiply attempts unhelpfully.

## Structured logging

For `package:logging`, pull individual fields:

```dart
import 'package:logging/logging.dart';

final log = Logger('cryptohopper');

on CryptohopperException catch (e) {
  log.severe('Cryptohopper request failed', e, StackTrace.current);
  // Or with explicit fields if your formatter knows about them:
  log.severe({
    'event': 'cryptohopper_error',
    'code': e.code,
    'status': e.status,
    'server_code': e.serverCode,
    'ip': e.ipAddress,
    'retry_after_ms': e.retryAfterMs,
    'message': e.message,
  });
}
```

### Sentry / Crashlytics on Flutter

Attach SDK metadata as breadcrumbs / context so you can filter dashboard events by `cryptohopper.code`:

```dart
import 'package:sentry_flutter/sentry_flutter.dart';

on CryptohopperException catch (e) {
  await Sentry.configureScope((scope) async {
    scope.setContexts('cryptohopper', {
      'code': e.code,
      'status': e.status,
      'server_code': e.serverCode,
      'ip_address': e.ipAddress,
    });
    scope.setTag('cryptohopper.code', e.code);
  });
  await Sentry.captureException(e, stackTrace: StackTrace.current);
  rethrow;
}
```

The `tag` lets you filter Sentry events by `cryptohopper.code` to see, e.g., a spike of `RATE_LIMITED` after a release.

## The `dynamic` return type

Most SDK methods return `Future<dynamic>` — typically `Map<String, dynamic>` or `List<dynamic>`. Cast as needed:

```dart
final me = await client.user.get() as Map<String, dynamic>;
final hoppers = await client.hoppers.list() as List<dynamic>;
```

If you want stricter typing, layer your own DTOs on top (see [Getting Started](Getting-Started.md) for examples). A future SDK version may ship typed response shapes via a code-generation feature; file an issue if that'd help.
