import 'dart:async';
import 'dart:convert';

import 'package:cryptohopper/cryptohopper.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as testing;

/// Test scaffold — wraps a [MockClient] and records every request the SDK
/// dispatches so assertions can introspect path, query, headers, and body.
class MockBackend {
  final List<http.BaseRequest> requests = [];
  final List<http.Response> _responses;
  int _index = 0;
  late CryptohopperClient client;

  MockBackend(
    List<http.Response> responses, {
    int maxRetries = 3,
    String? appKey,
  }) : _responses = responses {
    final mock = testing.MockClient((req) async {
      requests.add(req);
      if (_index >= _responses.length) {
        return http.Response('mock backend exhausted', 500);
      }
      return _responses[_index++];
    });

    client = CryptohopperClient(
      apiKey: 'test-token',
      appKey: appKey,
      maxRetries: maxRetries,
      httpClient: mock,
    );
  }

  http.BaseRequest get last {
    if (requests.isEmpty) {
      throw StateError('No requests recorded');
    }
    return requests.last;
  }

  /// Decoded JSON body of the last recorded request, or null if no body.
  Map<String, dynamic>? lastBodyJson() {
    final req = last;
    if (req is! http.Request) return null;
    if (req.body.isEmpty) return null;
    return jsonDecode(req.body) as Map<String, dynamic>;
  }
}
