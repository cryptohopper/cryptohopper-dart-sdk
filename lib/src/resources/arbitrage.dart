import '../transport.dart';

/// `client.arbitrage` — exchange + market arbitrage + shared backlog.
class Arbitrage {
  final Transport _transport;
  Arbitrage(this._transport);

  // Cross-exchange arbitrage.

  Future<dynamic> exchangeStart(Map<String, dynamic> data) =>
      _transport.request('POST', '/arbitrage/exchange', body: data);

  Future<dynamic> exchangeCancel({Map<String, dynamic>? data}) =>
      _transport.request('POST', '/arbitrage/cancel', body: data ?? const {});

  Future<dynamic> exchangeResults({Map<String, dynamic>? params}) => _transport.request(
        'GET',
        '/arbitrage/results',
        query: (params != null && params.isNotEmpty) ? params : null,
      );

  Future<dynamic> exchangeHistory({Map<String, dynamic>? params}) => _transport.request(
        'GET',
        '/arbitrage/history',
        query: (params != null && params.isNotEmpty) ? params : null,
      );

  Future<dynamic> exchangeTotal() => _transport.request('GET', '/arbitrage/total');

  Future<dynamic> exchangeResetTotal() =>
      _transport.request('POST', '/arbitrage/resettotal', body: const {});

  // Intra-exchange market arbitrage.

  Future<dynamic> marketStart(Map<String, dynamic> data) =>
      _transport.request('POST', '/arbitrage/market', body: data);

  Future<dynamic> marketCancel({Map<String, dynamic>? data}) =>
      _transport.request('POST', '/arbitrage/market-cancel', body: data ?? const {});

  Future<dynamic> marketResult({Map<String, dynamic>? params}) => _transport.request(
        'GET',
        '/arbitrage/market-result',
        query: (params != null && params.isNotEmpty) ? params : null,
      );

  Future<dynamic> marketHistory({Map<String, dynamic>? params}) => _transport.request(
        'GET',
        '/arbitrage/market-history',
        query: (params != null && params.isNotEmpty) ? params : null,
      );

  // Backlog (shared).

  Future<dynamic> backlogs({Map<String, dynamic>? params}) => _transport.request(
        'GET',
        '/arbitrage/get-backlogs',
        query: (params != null && params.isNotEmpty) ? params : null,
      );

  Future<dynamic> backlog(Object backlogId) =>
      _transport.request('GET', '/arbitrage/get-backlog', query: {'backlog_id': backlogId});

  Future<dynamic> deleteBacklog(Object backlogId) =>
      _transport.request('POST', '/arbitrage/delete-backlog', body: {'backlog_id': backlogId});
}
