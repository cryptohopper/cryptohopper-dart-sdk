import '../transport.dart';

/// `client.backtest` — run and inspect backtests.
class Backtest {
  final Transport _transport;
  Backtest(this._transport);

  Future<dynamic> create(Map<String, dynamic> data) =>
      _transport.request('POST', '/backtest/new', body: data);

  Future<dynamic> get(Object backtestId) =>
      _transport.request('GET', '/backtest/get', query: {'backtest_id': backtestId});

  Future<dynamic> list({Map<String, dynamic>? params}) => _transport.request(
        'GET',
        '/backtest/list',
        query: (params != null && params.isNotEmpty) ? params : null,
      );

  Future<dynamic> cancel(Object backtestId) =>
      _transport.request('POST', '/backtest/cancel', body: {'backtest_id': backtestId});

  Future<dynamic> restart(Object backtestId) =>
      _transport.request('POST', '/backtest/restart', body: {'backtest_id': backtestId});

  Future<dynamic> limits() => _transport.request('GET', '/backtest/limits');
}
