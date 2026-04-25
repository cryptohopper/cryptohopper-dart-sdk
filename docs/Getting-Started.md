# Getting Started

## Install

```bash
dart pub add cryptohopper
```

Or add to `pubspec.yaml`:

```yaml
dependencies:
  cryptohopper: ^0.1.0-alpha.1
```

Then:

```bash
dart pub get
```

Requires Dart 3.2 or newer (for field promotion in generic constraints, used internally). Works on the Dart VM, AOT-compiled binaries, and Flutter on every supported platform (iOS, Android, web, desktop).

## First call

```dart
import 'dart:io';
import 'package:cryptohopper/cryptohopper.dart';

Future<void> main() async {
  final client = CryptohopperClient(
    apiKey: Platform.environment['CRYPTOHOPPER_TOKEN']!,
  );

  try {
    final me = await client.user.get() as Map<String, dynamic>;
    print('Logged in as: ${me['email']}');

    final ticker = await client.exchange.ticker(
      exchange: 'binance',
      market: 'BTC/USDT',
    ) as Map<String, dynamic>;
    print('BTC/USDT: ${ticker['last']}');
  } on CryptohopperException catch (e) {
    stderr.writeln('${e.code} (${e.status}): ${e.message}');
  } finally {
    client.close();
  }
}
```

`CryptohopperClient` owns an `http.Client` internally — call `client.close()` when you're done with it (or pass your own and manage its lifecycle yourself).

## Getting a token

Every request (except a handful of public endpoints like `/exchange/ticker`) needs an OAuth2 bearer token. Create one via **Developer → Create App** on [cryptohopper.com](https://www.cryptohopper.com) and complete the consent flow. The token is a 40-character opaque string.

For local CLI scripts:

```bash
export CRYPTOHOPPER_TOKEN=<your-token>
```

For Flutter apps, **never** ship a token in your binary. The right pattern is OAuth in the app: open the consent flow in a `WebView` (or the platform browser via `url_launcher`), capture the redirect, and store the resulting token in the platform secure storage (`flutter_secure_storage`, iOS Keychain, Android EncryptedSharedPreferences).

## Idiomatic patterns

### `try/on CryptohopperException`

The SDK throws `CryptohopperException` for every API failure. Use Dart's `on` clause for typed catches:

```dart
try {
  await client.hoppers.get('999999');
} on CryptohopperException catch (e) {
  switch (e.code) {
    case 'NOT_FOUND':
      // expected; ignore
      break;
    case 'UNAUTHORIZED':
      await refreshToken();
      // retry
      break;
    case 'RATE_LIMITED':
      // SDK already retried; back off harder
      if (e.retryAfterMs != null) {
        await Future.delayed(Duration(milliseconds: e.retryAfterMs!));
      }
      break;
    case 'FORBIDDEN':
      print('Blocked from ${e.ipAddress}');
      break;
    default:
      rethrow;
  }
}
```

Compare error codes with `==` against the strings in `CryptohopperException.knownCodes` — they're stable across SDK versions.

### Customising the client

```dart
final client = CryptohopperClient(
  apiKey:     Platform.environment['CRYPTOHOPPER_TOKEN']!,
  appKey:     Platform.environment['CRYPTOHOPPER_APP_KEY'],
  baseUrl:    'https://api.cryptohopper.com/v1',  // override for staging
  timeout:    const Duration(seconds: 30),
  maxRetries: 3,                                  // 429 backoff; 0 disables
  userAgent:  'my-app/1.0',                       // appended after cryptohopper-sdk-dart/<v>
);
```

### Bringing your own `http.Client`

If you need custom transport behaviour — HTTP/2, TLS-pinning, BoringSSL on Flutter, OAuth-aware interceptors, or testing — pass any `package:http` `Client`:

```dart
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

// Example: HTTP/2 via cronet on Flutter Android
final myHttpClient = IOClient(HttpClient()
  ..connectionTimeout = const Duration(seconds: 10)
  ..badCertificateCallback = (cert, host, port) => false);

final client = CryptohopperClient(
  apiKey: token,
  httpClient: myHttpClient,
);
// You own this — `client.close()` won't close it.
```

When you supply your own `http.Client`, the SDK's `client.close()` won't close it. Manage its lifetime yourself.

## Common pitfalls

**`Null check operator used on a null value` from `Platform.environment[...]!`** — the env var isn't set in the process running your code. Validate at startup:

```dart
final token = Platform.environment['CRYPTOHOPPER_TOKEN'];
if (token == null || token.isEmpty) {
  stderr.writeln('CRYPTOHOPPER_TOKEN is not set');
  exit(1);
}
```

**`HandshakeException: CertificateException`** — on platforms with restrictive cert chains (older Android, corporate networks). For Flutter Android, prefer the `cronet_http` package which uses Android's system cert store. For desktop / server, install the corporate CA into the Dart-aware trust store or pass a custom `HttpClient` with the right `badCertificateCallback`.

**`SocketException: Connection failed (OS Error: Network is unreachable, errno = 101)`** — typical when your Flutter dev simulator can't reach the host network. The SDK surfaces this as `CryptohopperException` with `code: 'NETWORK_ERROR'`. Verify with `curl https://api.cryptohopper.com/v1/exchange/exchanges` from the simulator host.

**`UNAUTHORIZED` on every call** — token wrong, expired, or revoked. Visit the app page in the Cryptohopper dashboard.

**`FORBIDDEN` on endpoints that used to work** — IP allowlisting on the OAuth app blocked your current IP. The error includes the IP Cryptohopper saw:

```dart
on CryptohopperException catch (e) {
  if (e.code == 'FORBIDDEN') {
    print('Blocked from ${e.ipAddress}');
  }
}
```

For Flutter apps users will hit this less often (mobile carrier IP rotation), but if you've allowlisted server-side, mobile clients won't fit.

## Type signatures

Response shapes are returned as `dynamic` (typically `Map<String, dynamic>` or `List<dynamic>`) because the Cryptohopper API hasn't been frozen into stable typed models. To layer typed parsing on top, use `package:json_annotation` with `freezed` for code-generated DTOs, or hand-write small classes:

```dart
class Hopper {
  final int id;
  final String name;
  final String exchange;
  final bool enabled;

  Hopper({required this.id, required this.name, required this.exchange, required this.enabled});

  factory Hopper.fromJson(Map<String, dynamic> json) => Hopper(
    id: json['id'] as int,
    name: json['name'] as String,
    exchange: json['exchange'] as String,
    enabled: json['enabled'] as bool,
  );
}

final raw = await client.hoppers.get(42) as Map<String, dynamic>;
final hopper = Hopper.fromJson(raw);
```

## Next steps

- [Authentication](Authentication.md) — bearer flow, app keys, IP whitelisting, custom HTTP clients
- [Error Handling](Error-Handling.md) — every error code, recovery patterns, structured logging
- [Rate Limits](Rate-Limits.md) — auto-retry, customising back-off, concurrent requests
