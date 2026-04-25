import '../transport.dart';

/// `client.strategy` — user-defined trading strategies.
class Strategy {
  final Transport _transport;
  Strategy(this._transport);

  Future<dynamic> list() => _transport.request('GET', '/strategy/strategies');

  Future<dynamic> get(Object strategyId) =>
      _transport.request('GET', '/strategy/get', query: {'strategy_id': strategyId});

  Future<dynamic> create(Map<String, dynamic> data) =>
      _transport.request('POST', '/strategy/create', body: data);

  Future<dynamic> update(Object strategyId, Map<String, dynamic> data) =>
      _transport.request('POST', '/strategy/edit', body: {'strategy_id': strategyId, ...data});

  Future<dynamic> delete(Object strategyId) =>
      _transport.request('POST', '/strategy/delete', body: {'strategy_id': strategyId});
}
