import 'dart:async';
import 'dart:convert';
import 'dart:io' show HttpException, SocketException;

import 'package:http/http.dart' as http;

import 'exception.dart';
import 'version.dart';

/// Internal transport. Resources call this. SDK users shouldn't.
class Transport {
  static const String defaultBaseUrl = 'https://api.cryptohopper.com/v1';
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const int defaultMaxRetries = 3;

  final String _apiKey;
  final String? _appKey;
  final String _baseUrl;
  final Duration _timeout;
  final int _maxRetries;
  final String? _userAgent;
  final http.Client _httpClient;
  final bool _ownsClient;

  Transport({
    required String apiKey,
    String? appKey,
    String? baseUrl,
    Duration? timeout,
    int? maxRetries,
    String? userAgent,
    http.Client? httpClient,
  })  : _apiKey = apiKey,
        _appKey = appKey,
        _baseUrl = (baseUrl ?? defaultBaseUrl).replaceAll(RegExp(r'/+$'), ''),
        _timeout = timeout ?? defaultTimeout,
        _maxRetries = maxRetries ?? defaultMaxRetries,
        _userAgent = userAgent,
        _httpClient = httpClient ?? http.Client(),
        _ownsClient = httpClient == null {
    if (apiKey.isEmpty) {
      throw ArgumentError.value(apiKey, 'apiKey', 'must not be empty');
    }
  }

  /// Closes the underlying [http.Client] if and only if the transport created
  /// it. A bring-your-own client is left for the caller to manage.
  void close() {
    if (_ownsClient) _httpClient.close();
  }

  /// Perform a request against the Cryptohopper API. Unwraps the standard
  /// `{data: ...}` envelope and retries on HTTP 429 up to `maxRetries`.
  ///
  /// Returns whatever sits under the `data` key on success, or the raw decoded
  /// JSON body when there is no envelope.
  Future<dynamic> request(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Map<String, dynamic>? body,
  }) async {
    var attempt = 0;
    while (true) {
      try {
        return await _send(method, path, query, body);
      } on CryptohopperException catch (e) {
        if (e.code != 'RATE_LIMITED' || attempt >= _maxRetries) {
          rethrow;
        }
        final waitMs = e.retryAfterMs ?? (1000 * (1 << attempt));
        if (waitMs > 0) {
          await Future<void>.delayed(Duration(milliseconds: waitMs));
        }
        attempt++;
      }
    }
  }

  Future<dynamic> _send(
    String method,
    String path,
    Map<String, dynamic>? query,
    Map<String, dynamic>? body,
  ) async {
    final url = _buildUrl(path, query);
    final headers = _buildHeaders(hasBody: body != null);
    final payload = body != null ? jsonEncode(body) : null;

    final request = http.Request(method.toUpperCase(), Uri.parse(url));
    headers.forEach((k, v) => request.headers[k] = v);
    if (payload != null) request.body = payload;

    // Single deadline for the entire request lifecycle. send() resolves
    // once response headers arrive; the body is then drained in
    // Response.fromStream(). A naïve `.timeout(_timeout)` on send() alone
    // would let a slow or stalled response body hang the call indefinitely.
    // We split the deadline so the total never exceeds `_timeout`.
    final deadline = DateTime.now().add(_timeout);

    http.StreamedResponse streamed;
    try {
      streamed = await _httpClient.send(request).timeout(_timeout);
    } on TimeoutException catch (e) {
      throw CryptohopperException(
        code: 'TIMEOUT',
        message: 'Request timed out after ${_timeout.inSeconds}s: ${e.message ?? ''}',
        status: 0,
      );
    } on SocketException catch (e) {
      throw CryptohopperException(
        code: 'NETWORK_ERROR',
        message: 'Could not reach $_baseUrl (${e.message})',
        status: 0,
      );
    } on HttpException catch (e) {
      throw CryptohopperException(
        code: 'NETWORK_ERROR',
        message: e.message,
        status: 0,
      );
    }

    final remaining = deadline.difference(DateTime.now());
    if (remaining.isNegative || remaining == Duration.zero) {
      throw CryptohopperException(
        code: 'TIMEOUT',
        message: 'Response body read timed out after ${_timeout.inSeconds}s',
        status: 0,
      );
    }

    http.Response response;
    try {
      response = await http.Response.fromStream(streamed).timeout(remaining);
    } on TimeoutException catch (e) {
      throw CryptohopperException(
        code: 'TIMEOUT',
        message: 'Response body read timed out after ${_timeout.inSeconds}s: ${e.message ?? ''}',
        status: 0,
      );
    } on SocketException catch (e) {
      throw CryptohopperException(
        code: 'NETWORK_ERROR',
        message: 'Failed to read response body (${e.message})',
        status: 0,
      );
    } on HttpException catch (e) {
      throw CryptohopperException(
        code: 'NETWORK_ERROR',
        message: 'Failed to read response body: ${e.message}',
        status: 0,
      );
    }

    return _handleResponse(response);
  }

  String _buildUrl(String path, Map<String, dynamic>? query) {
    final fullPath = path.startsWith('/') ? path : '/$path';
    var url = '$_baseUrl$fullPath';

    if (query != null && query.isNotEmpty) {
      final clean = <String, String>{};
      query.forEach((k, v) {
        if (v != null) clean[k] = '$v';
      });
      if (clean.isNotEmpty) {
        final qs = clean.entries
            .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
            .join('&');
        url += url.contains('?') ? '&$qs' : '?$qs';
      }
    }

    return url;
  }

  Map<String, String> _buildHeaders({required bool hasBody}) {
    // Cryptohopper Public API v1 uses `access-token: <token>`, not the
    // OAuth2-conventional `Authorization: Bearer <token>`. The gateway in
    // front of the API rejects Bearer with a SigV4 parse error.
    final headers = <String, String>{
      'access-token': _apiKey,
      'Accept': 'application/json',
      'User-Agent': _buildUserAgent(),
    };
    if (_appKey != null && _appKey.isNotEmpty) {
      headers['x-api-app-key'] = _appKey;
    }
    if (hasBody) headers['Content-Type'] = 'application/json';
    return headers;
  }

  String _buildUserAgent() {
    final base = 'cryptohopper-sdk-dart/$sdkVersion';
    return _userAgent != null && _userAgent.isNotEmpty
        ? '$base $_userAgent'
        : base;
  }

  dynamic _handleResponse(http.Response response) {
    final status = response.statusCode;
    final raw = response.body;
    final parsed = _parseJson(raw);

    if (status >= 400) {
      throw _buildError(status, parsed, response);
    }

    if (parsed is Map<String, dynamic> && parsed.containsKey('data')) {
      return parsed['data'];
    }
    return parsed;
  }

  dynamic _parseJson(String raw) {
    if (raw.isEmpty) return null;
    try {
      return jsonDecode(raw);
    } on FormatException {
      return null;
    }
  }

  CryptohopperException _buildError(
    int status,
    dynamic parsed,
    http.Response response,
  ) {
    final body = parsed is Map<String, dynamic> ? parsed : <String, dynamic>{};
    final msg = body['message'] is String
        ? body['message'] as String
        : 'Request failed ($status)';
    final rawCode = body['code'];
    final serverCode = (rawCode is int && rawCode > 0) ? rawCode : null;
    final ipAddress = body['ip_address'] is String ? body['ip_address'] as String : null;
    final retryAfter = _parseRetryAfter(response.headers['retry-after']);

    return CryptohopperException(
      code: _defaultCodeForStatus(status),
      message: msg,
      status: status,
      serverCode: serverCode,
      ipAddress: ipAddress,
      retryAfterMs: retryAfter,
    );
  }

  String _defaultCodeForStatus(int status) {
    if (status == 400 || status == 422) return 'VALIDATION_ERROR';
    if (status == 401) return 'UNAUTHORIZED';
    if (status == 402) return 'DEVICE_UNAUTHORIZED';
    if (status == 403) return 'FORBIDDEN';
    if (status == 404) return 'NOT_FOUND';
    if (status == 409) return 'CONFLICT';
    if (status == 429) return 'RATE_LIMITED';
    if (status == 503) return 'SERVICE_UNAVAILABLE';
    if (status >= 500) return 'SERVER_ERROR';
    return 'UNKNOWN';
  }

  int? _parseRetryAfter(String? header) {
    if (header == null || header.isEmpty) return null;
    final asNum = num.tryParse(header);
    if (asNum != null) {
      if (asNum < 0) return null;
      return (asNum * 1000).round();
    }
    final asDate = HttpDate.tryParse(header);
    if (asDate == null) return null;
    final delta = asDate.difference(DateTime.now()).inMilliseconds;
    return delta < 0 ? 0 : delta;
  }
}

/// Minimal HTTP-date parser for the Retry-After header. Dart's `HttpDate.parse`
/// from `dart:io` would do this on the VM, but we keep this in-line for web
/// targets where `dart:io` isn't available — http package itself works on web.
class HttpDate {
  static DateTime? tryParse(String value) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      try {
        // RFC 1123: "Wed, 21 Oct 2015 07:28:00 GMT"
        return _rfc1123(value);
      } catch (_) {
        return null;
      }
    }
  }

  static DateTime _rfc1123(String s) {
    final parts = s.split(' ');
    if (parts.length < 5) throw const FormatException('not RFC1123');
    final day = int.parse(parts[1]);
    final month = const {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
      'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
    }[parts[2]];
    if (month == null) throw const FormatException('bad month');
    final year = int.parse(parts[3]);
    final time = parts[4].split(':');
    return DateTime.utc(
      year, month, day,
      int.parse(time[0]), int.parse(time[1]), int.parse(time[2]),
    );
  }
}
