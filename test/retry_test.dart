import 'package:cryptohopper/cryptohopper.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import 'mock_backend.dart';

void main() {
  group('Retry on 429', () {
    test('retries up to maxRetries and succeeds', () async {
      final backend = MockBackend([
        http.Response('{"message":"slow"}', 429, headers: {'retry-after': '0'}),
        http.Response('{"message":"slow"}', 429, headers: {'retry-after': '0'}),
        http.Response('{"data":{"ok":true}}', 200),
      ], maxRetries: 3);

      final result = await backend.client.user.get();
      expect(result, {'ok': true});
      expect(backend.requests.length, 3);
    });

    test('stops once maxRetries is exhausted', () async {
      final backend = MockBackend([
        http.Response('{"message":"slow"}', 429, headers: {'retry-after': '0'}),
        http.Response('{"message":"slow"}', 429, headers: {'retry-after': '0'}),
      ], maxRetries: 1);

      try {
        await backend.client.user.get();
        fail('Expected CryptohopperException');
      } on CryptohopperException catch (e) {
        expect(e.code, 'RATE_LIMITED');
        expect(backend.requests.length, 2);
      }
    });

    test('zero maxRetries disables backoff', () async {
      final backend = MockBackend(
        [http.Response('{"message":"slow"}', 429, headers: {'retry-after': '0'})],
        maxRetries: 0,
      );

      try {
        await backend.client.user.get();
        fail('Expected CryptohopperException');
      } on CryptohopperException catch (e) {
        expect(e.code, 'RATE_LIMITED');
        expect(backend.requests.length, 1);
      }
    });
  });
}
