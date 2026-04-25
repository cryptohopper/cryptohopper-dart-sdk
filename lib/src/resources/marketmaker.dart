import '../transport.dart';

/// `client.marketmaker` — market-maker bot ops + market-trend overrides + backlog.
class MarketMaker {
  final Transport _transport;
  MarketMaker(this._transport);

  Future<dynamic> get({Map<String, dynamic>? params}) => _transport.request(
        'GET',
        '/marketmaker/get',
        query: (params != null && params.isNotEmpty) ? params : null,
      );

  Future<dynamic> cancel({Map<String, dynamic>? data}) =>
      _transport.request('POST', '/marketmaker/cancel', body: data ?? const {});

  Future<dynamic> history({Map<String, dynamic>? params}) => _transport.request(
        'GET',
        '/marketmaker/history',
        query: (params != null && params.isNotEmpty) ? params : null,
      );

  // Market-trend overrides.

  Future<dynamic> getMarketTrend({Map<String, dynamic>? params}) => _transport.request(
        'GET',
        '/marketmaker/get-market-trend',
        query: (params != null && params.isNotEmpty) ? params : null,
      );

  Future<dynamic> setMarketTrend(Map<String, dynamic> data) =>
      _transport.request('POST', '/marketmaker/set-market-trend', body: data);

  Future<dynamic> deleteMarketTrend({Map<String, dynamic>? data}) =>
      _transport.request('POST', '/marketmaker/delete-market-trend', body: data ?? const {});

  // Backlog.

  Future<dynamic> backlogs({Map<String, dynamic>? params}) => _transport.request(
        'GET',
        '/marketmaker/get-backlogs',
        query: (params != null && params.isNotEmpty) ? params : null,
      );

  Future<dynamic> backlog(Object backlogId) =>
      _transport.request('GET', '/marketmaker/get-backlog', query: {'backlog_id': backlogId});

  Future<dynamic> deleteBacklog(Object backlogId) =>
      _transport.request('POST', '/marketmaker/delete-backlog', body: {'backlog_id': backlogId});
}
