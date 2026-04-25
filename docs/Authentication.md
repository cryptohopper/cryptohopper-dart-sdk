# Authentication

Every SDK request (except a handful of public endpoints) requires an OAuth2 bearer token:

```
Authorization: Bearer <40-char token>
```

## Obtaining a token

1. Log in to [cryptohopper.com](https://www.cryptohopper.com).
2. **Developer → Create App** — gives you a `client_id` + `client_secret`.
3. Complete the OAuth consent flow for your app, which returns a bearer token.

For Flutter mobile apps, the standard pattern is:

- Use `flutter_web_auth_2` or `appauth` to launch the OAuth consent flow in a system browser (so the user can use saved credentials / biometrics).
- Capture the redirect URL via a custom URL scheme registered for your app (`Info.plist` on iOS, `<intent-filter>` on Android).
- Persist the resulting bearer token in `flutter_secure_storage` (which uses iOS Keychain + Android EncryptedSharedPreferences under the hood).

For server-side Dart, use the [official CLI](https://github.com/cryptohopper/cryptohopper-cli) once interactively to obtain a token, then read it from your secret store at startup.

## Client construction

```dart
import 'package:cryptohopper/cryptohopper.dart';

final client = CryptohopperClient(
  apiKey:     Platform.environment['CRYPTOHOPPER_TOKEN']!,
  appKey:     Platform.environment['CRYPTOHOPPER_APP_KEY'],  // optional
  baseUrl:    'https://api.cryptohopper.com/v1',
  timeout:    const Duration(seconds: 30),
  maxRetries: 3,
  userAgent:  'my-app/1.0',
);
```

Only `apiKey:` is required.

### `appKey:`

Cryptohopper lets OAuth apps identify themselves on every request via the `x-api-app-key` header (value = your OAuth `client_id`). When set, the SDK adds the header automatically. Reasons to set it:

- Shows up in Cryptohopper's server-side telemetry — you can attribute your own traffic.
- Drives per-app rate limits — if two apps share a token, they get independent quotas.
- Harmless to omit; the server accepts unattributed requests.

Empty strings are treated as "not set," so passing `Platform.environment['…']` directly (which returns `null` when unset) is safe.

### `baseUrl:`

Override for staging or a local dev server. The default is `https://api.cryptohopper.com/v1`. The trailing `/v1` is part of the base; resource paths are relative to it.

```dart
final client = CryptohopperClient(
  apiKey: token,
  baseUrl: 'https://api.staging.cryptohopper.com/v1',
);
```

### `timeout:` and `maxRetries:`

`timeout:` is a `Duration` — the per-request total deadline. Defaults to 30 seconds. The Dart transport applies it as both connect and read timeout AND uses a deadline-based shim on `http.Response.fromStream` to ensure body reads can't exceed the budget either.

`maxRetries:` is the number of automatic retries on HTTP 429. Default 3. Set to 0 to disable. See [Rate Limits](Rate-Limits.md).

### `httpClient:` — bring your own `http.Client`

If you need custom transport behaviour — proxies, custom CA bundles, OAuth-aware interceptors, HTTP/2, BoringSSL on Flutter — pass any `package:http` `Client`:

```dart
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

final myHttpClient = IOClient(HttpClient()
  ..connectionTimeout = const Duration(seconds: 10));

final client = CryptohopperClient(
  apiKey: token,
  httpClient: myHttpClient,
);

// Important: when you supply httpClient, the SDK's `client.close()`
// will NOT close it. Close it yourself when done.
myHttpClient.close();
```

#### Flutter HTTP/2 via Cronet

For Flutter on Android, you can plug in Google's Cronet for HTTP/2 + better connection reuse:

```dart
import 'package:cronet_http/cronet_http.dart';

final cronet = CronetClient.fromCronetEngine(
  CronetEngine.build(cacheMode: CacheMode.memory),
);

final client = CryptohopperClient(apiKey: token, httpClient: cronet);
```

The trade-off: Cronet adds ~5MB to your APK. For most trading apps this is worth it — connection reuse on a flaky mobile network is a real UX win.

### `userAgent:`

Appended after the SDK's own User-Agent (`cryptohopper-sdk-dart/<version>`). Set this to identify your app to Cryptohopper support if you ever need to debug something with them.

## IP allowlisting

If your Cryptohopper app has IP allowlisting enabled, requests from unlisted IPs return `403 FORBIDDEN`. The SDK surfaces this as `CryptohopperException` with `code == 'FORBIDDEN'` and `ipAddress` populated:

```dart
on CryptohopperException catch (e) {
  if (e.code == 'FORBIDDEN') {
    print('Blocked: caller IP was ${e.ipAddress}');
  }
}
```

For mobile apps this is rarely useful — users connect from constantly-changing carrier IPs. If you have IP allowlisting on, your app needs to be server-side or rely on a known-stable VPN/proxy.

## Rotating tokens

Cryptohopper bearer tokens are long-lived but can be revoked:

- Manually from the dashboard.
- When the user revokes consent.

The SDK surfaces revocation as `UNAUTHORIZED` on the next call. There is no automatic refresh-token handling in the SDK today — handle the `UNAUTHORIZED` branch in your app: refresh, then construct a new client (the SDK's `apiKey` is final after construction):

```dart
class CryptohopperGateway {
  CryptohopperClient _client;
  final TokenStore _tokens;

  CryptohopperGateway(this._tokens) : _client = CryptohopperClient(apiKey: _tokens.current);

  Future<T> call<T>(Future<T> Function(CryptohopperClient) fn) async {
    try {
      return await fn(_client);
    } on CryptohopperException catch (e) {
      if (e.code != 'UNAUTHORIZED') rethrow;

      _client.close();
      _client = CryptohopperClient(apiKey: await _tokens.refresh());
      return await fn(_client);
    }
  }

  void close() => _client.close();
}
```

For Flutter apps, wire this through Riverpod / Provider / GetX so the singleton is replaced atomically.

## Concurrency

`CryptohopperClient` is **not** designed for shared use across isolates — `package:http` Clients are tied to the isolate that created them. One client per isolate is fine.

For concurrent outbound calls within a single isolate, use `Future.wait`:

```dart
final futures = hopperIds.map((id) => client.hoppers.get(id));
final results = await Future.wait(futures);
```

This sends all requests in parallel, bounded by the underlying `http.Client`'s connection pool. See [Rate Limits](Rate-Limits.md) for guidance on capping concurrency at the API quota.

## Public-only access (no token)

A handful of endpoints accept anonymous calls:

- `/market/*` — marketplace browse
- `/platform/*` — i18n, country list, blog feed
- `/exchange/ticker`, `/exchange/candle`, `/exchange/orderbook`, `/exchange/markets`, `/exchange/exchanges`, `/exchange/forex-rates` — public market data

The SDK still requires a non-empty `apiKey:` at construction; pass any placeholder if you only intend to hit public endpoints. The server ignores the bearer header on whitelisted routes.

```dart
final client = CryptohopperClient(apiKey: 'anonymous');
final btc = await client.exchange.ticker(exchange: 'binance', market: 'BTC/USDT');
```
