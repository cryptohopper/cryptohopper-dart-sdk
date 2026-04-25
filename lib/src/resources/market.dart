import '../transport.dart';

/// `client.market` — marketplace browse (public).
class Market {
  final Transport _transport;
  Market(this._transport);

  Future<dynamic> signals({Map<String, dynamic>? params}) => _transport.request(
        'GET',
        '/market/signals',
        query: (params != null && params.isNotEmpty) ? params : null,
      );

  Future<dynamic> signal(Object signalId) =>
      _transport.request('GET', '/market/signal', query: {'signal_id': signalId});

  Future<dynamic> items({Map<String, dynamic>? params}) => _transport.request(
        'GET',
        '/market/marketitems',
        query: (params != null && params.isNotEmpty) ? params : null,
      );

  Future<dynamic> item(Object itemId) =>
      _transport.request('GET', '/market/marketitem', query: {'item_id': itemId});

  Future<dynamic> homepage() => _transport.request('GET', '/market/homepage');
}
