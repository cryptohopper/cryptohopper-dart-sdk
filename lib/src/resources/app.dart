import '../transport.dart';

/// `client.app` — mobile app store receipts + in-app purchases.
class App {
  final Transport _transport;
  App(this._transport);

  Future<dynamic> receipt(Map<String, dynamic> data) =>
      _transport.request('POST', '/app/receipt', body: data);

  Future<dynamic> inAppPurchase(Map<String, dynamic> data) =>
      _transport.request('POST', '/app/in_app_purchase', body: data);
}
