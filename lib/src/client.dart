import 'package:http/http.dart' as http;

import 'resources/ai.dart';
import 'resources/app.dart';
import 'resources/arbitrage.dart';
import 'resources/backtest.dart';
import 'resources/chart.dart';
import 'resources/exchange.dart';
import 'resources/hoppers.dart';
import 'resources/market.dart';
import 'resources/marketmaker.dart';
import 'resources/platform.dart';
import 'resources/signals.dart';
import 'resources/social.dart';
import 'resources/strategy.dart';
import 'resources/subscription.dart';
import 'resources/template.dart';
import 'resources/tournaments.dart';
import 'resources/user.dart';
import 'resources/webhooks.dart';
import 'transport.dart';

/// Asynchronous Cryptohopper API client.
///
/// ```dart
/// final client = CryptohopperClient(apiKey: token);
/// final me = await client.user.get();
/// final ticker = await client.exchange.ticker(
///   exchange: 'binance',
///   market: 'BTC/USDT',
/// );
/// client.close();
/// ```
class CryptohopperClient {
  final Transport _transport;

  late final User user;
  late final Hoppers hoppers;
  late final Exchange exchange;
  late final Strategy strategy;
  late final Backtest backtest;
  late final Market market;
  late final Signals signals;
  late final Arbitrage arbitrage;
  late final MarketMaker marketmaker;
  late final Template template;
  late final Ai ai;
  late final Platform platform;
  late final Chart chart;
  late final Subscription subscription;
  late final Social social;
  late final Tournaments tournaments;
  late final Webhooks webhooks;
  late final App app;

  /// Build a Cryptohopper client.
  ///
  /// * [apiKey] — 40-char OAuth2 bearer token (required).
  /// * [appKey] — Optional OAuth client_id, sent as `x-api-app-key` so the
  ///   server can attribute traffic and apply per-app rate limits.
  /// * [baseUrl] — Override for staging or a local dev server. Defaults to
  ///   `https://api.cryptohopper.com/v1`.
  /// * [timeout] — Per-request timeout. Defaults to 30 seconds.
  /// * [maxRetries] — Retries on HTTP 429 honouring `Retry-After`. Pass `0`
  ///   to disable. Defaults to 3.
  /// * [userAgent] — Appended after `cryptohopper-sdk-dart/<version>`.
  /// * [httpClient] — Bring-your-own [http.Client] (mainly for tests). When
  ///   provided, the caller is responsible for closing it.
  CryptohopperClient({
    required String apiKey,
    String? appKey,
    String? baseUrl,
    Duration? timeout,
    int? maxRetries,
    String? userAgent,
    http.Client? httpClient,
  }) : _transport = Transport(
          apiKey: apiKey,
          appKey: appKey,
          baseUrl: baseUrl,
          timeout: timeout,
          maxRetries: maxRetries,
          userAgent: userAgent,
          httpClient: httpClient,
        ) {
    user = User(_transport);
    hoppers = Hoppers(_transport);
    exchange = Exchange(_transport);
    strategy = Strategy(_transport);
    backtest = Backtest(_transport);
    market = Market(_transport);
    signals = Signals(_transport);
    arbitrage = Arbitrage(_transport);
    marketmaker = MarketMaker(_transport);
    template = Template(_transport);
    ai = Ai(_transport);
    platform = Platform(_transport);
    chart = Chart(_transport);
    subscription = Subscription(_transport);
    social = Social(_transport);
    tournaments = Tournaments(_transport);
    webhooks = Webhooks(_transport);
    app = App(_transport);
  }

  /// Closes the underlying HTTP client when the SDK created it. Bring-your-own
  /// clients are left for the caller to manage.
  void close() => _transport.close();
}
