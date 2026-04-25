import '../transport.dart';

/// `client.chart` — saved chart layouts + shared chart links.
class Chart {
  final Transport _transport;
  Chart(this._transport);

  Future<dynamic> list() => _transport.request('GET', '/chart/list');

  Future<dynamic> get(Object chartId) =>
      _transport.request('GET', '/chart/get', query: {'chart_id': chartId});

  Future<dynamic> save(Map<String, dynamic> data) =>
      _transport.request('POST', '/chart/save', body: data);

  Future<dynamic> delete(Object chartId) =>
      _transport.request('POST', '/chart/delete', body: {'chart_id': chartId});

  Future<dynamic> shareSave(Map<String, dynamic> data) =>
      _transport.request('POST', '/chart/share-save', body: data);

  Future<dynamic> shareGet(Object shareId) =>
      _transport.request('GET', '/chart/share-get', query: {'share_id': shareId});
}
