import '../transport.dart';

/// `client.webhooks` — developer webhook registration.
/// Maps to the server's `/api/webhook_*` endpoints; named for clarity.
class Webhooks {
  final Transport _transport;
  Webhooks(this._transport);

  Future<dynamic> create(Map<String, dynamic> data) =>
      _transport.request('POST', '/api/webhook_create', body: data);

  Future<dynamic> delete(Object webhookId) =>
      _transport.request('POST', '/api/webhook_delete', body: {'webhook_id': webhookId});
}
