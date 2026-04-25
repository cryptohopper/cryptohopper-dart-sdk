# Rate Limits

Cryptohopper applies per-bucket rate limits on the server. When you hit one, you get a `429` with a `Retry-After` header. The SDK handles this for you.

## The default behaviour

On every `429`, the SDK:

1. Parses `Retry-After` (either seconds-as-integer or HTTP-date form) into milliseconds.
2. Sleeps that long via `Future.delayed` (falling back to exponential back-off if the header is missing).
3. Retries the request.
4. Repeats up to `maxRetries:` (default 3).

If retries exhaust, the call throws `CryptohopperException` with `code == 'RATE_LIMITED'` and `retryAfterMs` set to the last seen retry hint.

## Configuring it

```dart
final client = CryptohopperClient(
  apiKey:     token,
  maxRetries: 10,
  timeout:    const Duration(seconds: 60),  // bump if 10 retries push past 30s total
);
```

To **disable** retries entirely (e.g. you want to do your own back-off):

```dart
final client = CryptohopperClient(apiKey: token, maxRetries: 0);
```

With `maxRetries: 0`, a 429 throws immediately as `RATE_LIMITED`. Inspect `e.retryAfterMs` and schedule the retry on your own timeline.

## Buckets

Cryptohopper has three named buckets:

| Bucket | Scope | Example endpoints |
|---|---|---|
| `normal` | Most reads + writes | `/user/get`, `/hopper/list`, `/hopper/update`, `/exchange/ticker` |
| `order` | Anything that places or modifies orders | `/hopper/buy`, `/hopper/sell`, `/hopper/panic` |
| `backtest` | The (expensive) backtest subsystem | `/backtest/new`, `/backtest/get` |

The SDK doesn't know which bucket a call hits — it only sees the 429. You don't need to either; the server tells you when you're limited.

## Backfill jobs (own back-off)

If you're ingesting historical data and need to fetch many pages, take ownership of the back-off:

```dart
import 'package:cryptohopper/cryptohopper.dart';

final client = CryptohopperClient(apiKey: token, maxRetries: 0);

for (final hopperId in allHopperIds) {
  while (true) {
    try {
      final orders = await client.hoppers.orders(hopperId);
      await process(orders);
      break;
    } on CryptohopperException catch (e) {
      if (e.code != 'RATE_LIMITED') rethrow;
      final waitMs = e.retryAfterMs ?? 1000;
      await Future.delayed(Duration(milliseconds: waitMs));
    }
  }
}
```

This pattern lets a long-running job honour rate limits without stalling other work, because you decide the pacing.

## Capping concurrency

`Future.wait` runs everything in parallel — perfect for quick fan-out, but trips rate limits at scale. To bound concurrency, use `package:pool`:

```dart
import 'package:pool/pool.dart';

final pool = Pool(4);  // 4 concurrent workers

final results = await Future.wait(
  hopperIds.map((id) => pool.withResource(() => client.hoppers.get(id))),
);
```

Empirically, **4–8 concurrent workers** is comfortable for most accounts. Higher is feasible with `appKey:` set (which gives your OAuth app its own quota) but plan to back off explicitly.

## Flutter UI integration

For Flutter apps, you typically want loading states + retry UX, not silent retries. Wire the SDK into your state management of choice:

### Riverpod example

```dart
final hoppersProvider = AsyncNotifierProvider<HoppersNotifier, List<dynamic>>(
  HoppersNotifier.new,
);

class HoppersNotifier extends AsyncNotifier<List<dynamic>> {
  late CryptohopperClient _client;

  @override
  Future<List<dynamic>> build() async {
    _client = ref.watch(cryptohopperClientProvider);
    return await _client.hoppers.list() as List<dynamic>;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _client.hoppers.list() as List<dynamic>;
    });
  }
}
```

`AsyncValue.guard` automatically captures `CryptohopperException` and surfaces it through the `state.error` field, which your `Consumer` can render appropriately.

### Pull-to-refresh + offline awareness

```dart
RefreshIndicator(
  onRefresh: () => ref.read(hoppersProvider.notifier).refresh(),
  child: hoppersAsync.when(
    loading: () => const CircularProgressIndicator(),
    error: (e, _) => switch (e) {
      CryptohopperException(code: 'NETWORK_ERROR') =>
        const Text("You're offline. Pull down to retry."),
      CryptohopperException(code: 'TIMEOUT') =>
        const Text("Cryptohopper is slow right now. Please try again."),
      CryptohopperException(code: 'UNAUTHORIZED') =>
        SignInButton(onPressed: ref.read(authProvider.notifier).signIn),
      _ => Text('Error: $e'),
    },
    data: (hoppers) => HoppersList(hoppers: hoppers),
  ),
)
```

## What the SDK does NOT do

- **No global semaphore.** If you spawn many parallel requests via `Future.wait`, every retry is independent — you might get many simultaneous `Future.delayed` calls. Cap concurrency with `package:pool`.
- **No adaptive slow-down.** After a 429, the SDK waits and retries that one call. It doesn't throttle future calls.
- **No client-side bucket tracking.** The server is the source of truth.
- **No isolate-aware coordination.** If you spawn many isolates each running their own SDK client, they don't share retry state.

## Diagnosing "always rate-limited"

If every request throws `RATE_LIMITED` even at low volume:

1. Check that your app hasn't been flagged for abuse in the Cryptohopper dashboard.
2. Confirm your retry logic doesn't accidentally retry on non-429 errors too — `e.code == 'RATE_LIMITED'` is the canonical guard.
3. Inspect `e.serverCode` — Cryptohopper sometimes includes a numeric detail there that clarifies which bucket you've tripped.
4. If many users share a token (rare, but happens with embedded read-only credentials), they all share one quota. Issue a per-user OAuth app instead.

## Hot-reload caveat

Flutter's hot-reload doesn't dispose old `http.Client` instances. If you reload while a request is in flight, the SDK's `Future.delayed` retries can outlive the reload — you'll see "ghost" requests fired against an old token after re-login during dev. Two mitigations:

- Use a Riverpod `autoDispose` provider for the SDK client so it's torn down between reloads.
- Wrap top-level SDK calls in a `Future.delayed(Duration.zero)` to push them past the reload boundary.

This isn't a problem in production — release builds don't hot-reload.
