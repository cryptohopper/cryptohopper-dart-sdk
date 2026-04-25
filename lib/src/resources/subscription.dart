import '../transport.dart';

/// `client.subscription` — plans, per-hopper state, credits, billing.
class Subscription {
  final Transport _transport;
  Subscription(this._transport);

  Future<dynamic> hopper(Object hopperId) =>
      _transport.request('GET', '/subscription/hopper', query: {'hopper_id': hopperId});

  Future<dynamic> get() => _transport.request('GET', '/subscription/get');

  Future<dynamic> plans() => _transport.request('GET', '/subscription/plans');

  Future<dynamic> remap(Map<String, dynamic> data) =>
      _transport.request('POST', '/subscription/remap', body: data);

  Future<dynamic> assign(Map<String, dynamic> data) =>
      _transport.request('POST', '/subscription/assign', body: data);

  Future<dynamic> getCredits() => _transport.request('GET', '/subscription/getcredits');

  Future<dynamic> orderSub(Map<String, dynamic> data) =>
      _transport.request('POST', '/subscription/ordersub', body: data);

  Future<dynamic> stopSubscription({Map<String, dynamic>? data}) =>
      _transport.request('POST', '/subscription/stopsubscription', body: data ?? const {});
}
