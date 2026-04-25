# cryptohopper

[![pub.dev](https://img.shields.io/pub/v/cryptohopper?include_prereleases&logo=dart)](https://pub.dev/packages/cryptohopper)
[![pub points](https://img.shields.io/pub/points/cryptohopper?logo=dart)](https://pub.dev/packages/cryptohopper/score)
[![CI](https://github.com/cryptohopper/cryptohopper-dart-sdk/actions/workflows/ci.yml/badge.svg)](https://github.com/cryptohopper/cryptohopper-dart-sdk/actions/workflows/ci.yml)
[![Dart SDK](https://img.shields.io/badge/dart-3.0%2B-blue?logo=dart)](pubspec.yaml)
[![License: MIT](https://img.shields.io/github/license/cryptohopper/cryptohopper-dart-sdk?color=blue)](LICENSE)

Official Dart SDK for the [Cryptohopper](https://www.cryptohopper.com) API.

> **Status: 0.1.0-alpha.1** — full coverage of all 18 public API domains: `user`, `hoppers`, `exchange`, `strategy`, `backtest`, `market`, `signals`, `arbitrage`, `marketmaker`, `template`, `ai`, `platform`, `chart`, `subscription`, `social`, `tournaments`, `webhooks`, `app`.

**Deeper docs:** [Getting Started](docs/Getting-Started.md) · [Authentication](docs/Authentication.md) · [Error Handling](docs/Error-Handling.md) · [Rate Limits](docs/Rate-Limits.md)

## Install

```yaml
# pubspec.yaml
dependencies:
  cryptohopper: ^0.1.0-alpha.1
```

```bash
dart pub get
```

Requires Dart 3.0 or newer. Works on the Dart VM, AOT-compiled binaries, and Flutter on every supported platform (iOS, Android, web, desktop).

## Quickstart

```dart
import 'dart:io';
import 'package:cryptohopper/cryptohopper.dart';

Future<void> main() async {
  final client = CryptohopperClient(
    apiKey: Platform.environment['CRYPTOHOPPER_TOKEN']!,
  );

  try {
    final me = await client.user.get();
    print('Logged in as: ${me['email']}');

    final hoppers = await client.hoppers.list(exchange: 'binance') as List;
    for (final h in hoppers) {
      print('  hopper ${h['id']}: ${h['name']}');
    }

    final ticker = await client.exchange.ticker(
      exchange: 'binance',
      market: 'BTC/USDT',
    );
    print('BTC/USDT: ${ticker['last']}');
  } on CryptohopperException catch (e) {
    stderr.writeln('${e.code} (${e.status}): ${e.message}');
    if (e.code == 'RATE_LIMITED' && e.retryAfterMs != null) {
      stderr.writeln('Retry after ${e.retryAfterMs}ms');
    }
  } finally {
    client.close();
  }
}
```

## Authentication

Every request (except a handful of public endpoints) needs a 40-character OAuth2 bearer token. Issue one through the developer dashboard on [cryptohopper.com](https://www.cryptohopper.com), then:

```dart
final client = CryptohopperClient(
  apiKey: 'your-40-char-oauth-token',
  appKey: 'your-oauth-client-id', // optional, sent as x-api-app-key
);
```

The optional `appKey` carries your OAuth `client_id` for per-app rate-limit attribution.

## Configuration

```dart
final client = CryptohopperClient(
  apiKey:     Platform.environment['CRYPTOHOPPER_TOKEN']!,
  appKey:     Platform.environment['CRYPTOHOPPER_APP_KEY'],
  baseUrl:    'https://api.cryptohopper.com/v1',  // override for staging
  timeout:    const Duration(seconds: 30),         // per-request
  maxRetries: 3,                                   // 429 backoff; 0 disables
  userAgent:  'my-app/1.0',                        // appended after cryptohopper-sdk-dart/<v>
);
```

## Errors

Every non-2xx response (and every network/timeout failure) raises `CryptohopperException`:

```dart
try {
  await client.hoppers.get('not-a-real-id');
} on CryptohopperException catch (e) {
  e.code;          // 'NOT_FOUND', 'UNAUTHORIZED', 'RATE_LIMITED', ...
  e.status;        // HTTP status (0 on network failure)
  e.serverCode;    // numeric Cryptohopper code when present
  e.ipAddress;     // server-reported caller IP, when included
  e.retryAfterMs;  // parsed Retry-After (only on 429)
}
```

Codes are stable across every official Cryptohopper SDK (Node, Python, Go, Ruby, Rust, PHP, Dart). Compare with `==`, never substring-match.

## Rate limits

On HTTP 429 the client sleeps for `Retry-After` seconds (or an exponential-backoff fallback) and retries up to `maxRetries` times. The final failure surfaces as `CryptohopperException` with `code == 'RATE_LIMITED'` and `retryAfterMs` populated.

## Testing your code

Inject a `MockClient` from `package:http`'s testing module:

```dart
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;

final mock = MockClient((req) async {
  // Inspect req.url, req.method, req.body, req.headers...
  return http.Response('{"data":{"id":42}}', 200);
});

final client = CryptohopperClient(
  apiKey: 'test-token',
  httpClient: mock,
);

final result = await client.user.get();
expect(result, {'id': 42});
```

The SDK test suite uses exactly this pattern — see [`test/`](test/) for examples covering error mapping, retry behaviour, and resource path wiring.

## Versioning

Semantic versioning. While on `0.x`, minor releases can ship breaking changes — they're called out in [CHANGELOG.md](CHANGELOG.md). See the [shared versioning policy](https://github.com/cryptohopper/cryptohopper-resources/blob/main/VERSIONING.md) for the full SDK-wide rules.

## Other Cryptohopper SDKs

| Language | Install |
|---|---|
| Node.js / TypeScript | `npm i @cryptohopper/sdk` |
| Python | `pip install cryptohopper` |
| Go | `go get github.com/cryptohopper/cryptohopper-go-sdk` |
| Ruby | `gem install cryptohopper --pre` |
| Rust | `cargo add cryptohopper` |
| PHP | `composer require cryptohopper/sdk` |
| CLI | `npm i -g @cryptohopper/cli` or [download a binary](https://github.com/cryptohopper/cryptohopper-cli/releases/latest) |

## License

MIT — see [LICENSE](LICENSE).
