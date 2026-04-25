import '../transport.dart';

/// `client.template` — bot templates (reusable hopper configurations).
class Template {
  final Transport _transport;
  Template(this._transport);

  Future<dynamic> list() => _transport.request('GET', '/template/templates');

  Future<dynamic> get(Object templateId) =>
      _transport.request('GET', '/template/get', query: {'template_id': templateId});

  Future<dynamic> basic(Object templateId) =>
      _transport.request('GET', '/template/basic', query: {'template_id': templateId});

  Future<dynamic> save(Map<String, dynamic> data) =>
      _transport.request('POST', '/template/save-template', body: data);

  Future<dynamic> update(Object templateId, Map<String, dynamic> data) => _transport.request(
        'POST',
        '/template/update',
        body: {'template_id': templateId, ...data},
      );

  Future<dynamic> load(Object templateId, Object hopperId) => _transport.request(
        'POST',
        '/template/load',
        body: {'template_id': templateId, 'hopper_id': hopperId},
      );

  Future<dynamic> delete(Object templateId) =>
      _transport.request('POST', '/template/delete', body: {'template_id': templateId});
}
