import '../transport.dart';

/// `client.exchange` — public market data (no auth required for most endpoints).
class Exchange {
  final Transport _transport;
  Exchange(this._transport);

  Future<dynamic> ticker({required String exchange, required String market}) =>
      _transport.request('GET', '/exchange/ticker', query: {
        'exchange': exchange,
        'market': market,
      });

  Future<dynamic> candles({
    required String exchange,
    required String market,
    required String timeframe,
    int? from,
    int? to,
  }) =>
      _transport.request('GET', '/exchange/candle', query: {
        'exchange': exchange,
        'market': market,
        'timeframe': timeframe,
        'from': from,
        'to': to,
      });

  Future<dynamic> orderbook({required String exchange, required String market}) =>
      _transport.request('GET', '/exchange/orderbook', query: {
        'exchange': exchange,
        'market': market,
      });

  Future<dynamic> markets(String exchange) =>
      _transport.request('GET', '/exchange/markets', query: {'exchange': exchange});

  Future<dynamic> currencies(String exchange) =>
      _transport.request('GET', '/exchange/currencies', query: {'exchange': exchange});

  Future<dynamic> exchanges() => _transport.request('GET', '/exchange/exchanges');

  Future<dynamic> forexRates() => _transport.request('GET', '/exchange/forex-rates');
}
