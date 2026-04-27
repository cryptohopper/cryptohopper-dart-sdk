import 'package:cryptohopper/cryptohopper.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import 'mock_backend.dart';

void main() {
  group('CryptohopperClient', () {
    test('rejects empty apiKey', () {
      expect(
        () => CryptohopperClient(apiKey: ''),
        throwsArgumentError,
      );
    });

    test('sends access-token + user agent on every request', () async {
      final backend = MockBackend([http.Response('{"data":{"id":1}}', 200)]);
      await backend.client.user.get();

      final req = backend.last;
      expect(req.headers['access-token'], 'test-token');
      expect(req.headers.containsKey('Authorization'), isFalse,
          reason: 'Cryptohopper v1 uses access-token, not Authorization: Bearer');
      expect(req.headers['User-Agent'], startsWith('cryptohopper-sdk-dart/$sdkVersion'));
      expect(req.headers['Accept'], 'application/json');
      expect(req.headers.containsKey('x-api-app-key'), isFalse);
    });

    test('includes x-api-app-key when configured', () async {
      final backend = MockBackend(
        [http.Response('{"data":{}}', 200)],
        appKey: 'my-client-id',
      );
      await backend.client.user.get();
      expect(backend.last.headers['x-api-app-key'], 'my-client-id');
    });

    test('unwraps the data envelope', () async {
      final backend = MockBackend(
        [http.Response('{"data":{"id":42,"name":"bot"}}', 200)],
      );
      final result = await backend.client.user.get();
      expect(result, {'id': 42, 'name': 'bot'});
    });

    test('returns parsed JSON when no envelope', () async {
      final backend = MockBackend([http.Response('[1,2,3]', 200)]);
      final result = await backend.client.exchange.exchanges();
      expect(result, [1, 2, 3]);
    });

    test('builds query string from named params', () async {
      final backend = MockBackend([http.Response('{"data":[]}', 200)]);
      await backend.client.exchange.ticker(exchange: 'binance', market: 'BTC/USDT');
      final url = backend.last.url;
      expect(url.path, endsWith('/exchange/ticker'));
      expect(url.queryParameters, containsPair('exchange', 'binance'));
      expect(url.queryParameters, containsPair('market', 'BTC/USDT'));
    });

    test('drops null query params', () async {
      final backend = MockBackend([http.Response('{"data":[]}', 200)]);
      await backend.client.exchange.candles(
        exchange: 'binance',
        market: 'BTC/USDT',
        timeframe: '1h',
      );
      final qp = backend.last.url.queryParameters;
      expect(qp.containsKey('from'), isFalse);
      expect(qp.containsKey('to'), isFalse);
    });

    test('POST body is JSON-encoded with content-type', () async {
      final backend = MockBackend([http.Response('{"data":{"ok":true}}', 200)]);
      await backend.client.hoppers.create({'name': 'test-bot', 'exchange': 'binance'});

      final req = backend.last;
      expect(req.method, 'POST');
      // Dart's http.Request appends `; charset=utf-8` automatically when the
      // body is a string, so match the prefix instead of exact equality.
      expect(req.headers['Content-Type'], startsWith('application/json'));
      expect(backend.lastBodyJson(), {'name': 'test-bot', 'exchange': 'binance'});
    });
  });
}
