import '../transport.dart';

/// `client.signals` — signal-provider analytics. Distinct from the
/// marketplace browse at `client.market.signals`.
class Signals {
  final Transport _transport;
  Signals(this._transport);

  Future<dynamic> list({Map<String, dynamic>? params}) => _transport.request(
        'GET',
        '/signals/signals',
        query: (params != null && params.isNotEmpty) ? params : null,
      );

  Future<dynamic> performance({Map<String, dynamic>? params}) => _transport.request(
        'GET',
        '/signals/performance',
        query: (params != null && params.isNotEmpty) ? params : null,
      );

  Future<dynamic> stats() => _transport.request('GET', '/signals/stats');

  Future<dynamic> distribution() => _transport.request('GET', '/signals/distribution');

  Future<dynamic> chartData({Map<String, dynamic>? params}) => _transport.request(
        'GET',
        '/signals/chartdata',
        query: (params != null && params.isNotEmpty) ? params : null,
      );
}
