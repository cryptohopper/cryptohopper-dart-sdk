import 'package:cryptohopper/cryptohopper.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import 'mock_backend.dart';

void main() {
  group('CryptohopperException', () {
    final cases = <int, String>{
      400: 'VALIDATION_ERROR',
      401: 'UNAUTHORIZED',
      402: 'DEVICE_UNAUTHORIZED',
      403: 'FORBIDDEN',
      404: 'NOT_FOUND',
      409: 'CONFLICT',
      422: 'VALIDATION_ERROR',
      429: 'RATE_LIMITED',
      500: 'SERVER_ERROR',
      503: 'SERVICE_UNAVAILABLE',
      418: 'UNKNOWN',
    };

    for (final entry in cases.entries) {
      test('maps HTTP ${entry.key} → ${entry.value}', () async {
        final backend = MockBackend(
          [http.Response('{"code":0,"message":"bad"}', entry.key)],
          maxRetries: 0,
        );

        try {
          await backend.client.user.get();
          fail('Expected CryptohopperException');
        } on CryptohopperException catch (e) {
          expect(e.code, entry.value);
          expect(e.status, entry.key);
          expect(e.message, 'bad');
        }
      });
    }

    test('exposes server code and IP address', () async {
      final body = '{"code":4210,"message":"ip not allowed","ip_address":"203.0.113.5"}';
      final backend = MockBackend([http.Response(body, 403)], maxRetries: 0);

      try {
        await backend.client.hoppers.list();
        fail('Expected CryptohopperException');
      } on CryptohopperException catch (e) {
        expect(e.code, 'FORBIDDEN');
        expect(e.serverCode, 4210);
        expect(e.ipAddress, '203.0.113.5');
      }
    });

    test('parses Retry-After numeric seconds', () async {
      final backend = MockBackend(
        [http.Response('{"message":"slow down"}', 429, headers: {'retry-after': '2'})],
        maxRetries: 0,
      );

      try {
        await backend.client.user.get();
        fail('Expected CryptohopperException');
      } on CryptohopperException catch (e) {
        expect(e.code, 'RATE_LIMITED');
        expect(e.retryAfterMs, 2000);
      }
    });

    test('handles unparseable body gracefully', () async {
      final backend = MockBackend(
        [http.Response('not-json', 500)],
        maxRetries: 0,
      );

      try {
        await backend.client.user.get();
        fail('Expected CryptohopperException');
      } on CryptohopperException catch (e) {
        expect(e.code, 'SERVER_ERROR');
        expect(e.status, 500);
      }
    });
  });
}
