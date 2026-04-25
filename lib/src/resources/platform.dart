import '../transport.dart';

/// `client.platform` — marketing / i18n / discovery reads (all public).
class Platform {
  final Transport _transport;
  Platform(this._transport);

  Future<dynamic> latestBlog({Map<String, dynamic>? params}) => _transport.request(
        'GET',
        '/platform/latestblog',
        query: (params != null && params.isNotEmpty) ? params : null,
      );

  Future<dynamic> documentation({Map<String, dynamic>? params}) => _transport.request(
        'GET',
        '/platform/documentation',
        query: (params != null && params.isNotEmpty) ? params : null,
      );

  Future<dynamic> promoBar() => _transport.request('GET', '/platform/promobar');

  Future<dynamic> searchDocumentation(String query) =>
      _transport.request('GET', '/platform/searchdocumentation', query: {'q': query});

  Future<dynamic> countries() => _transport.request('GET', '/platform/countries');

  Future<dynamic> countryAllowlist() =>
      _transport.request('GET', '/platform/countryallowlist');

  Future<dynamic> ipCountry() => _transport.request('GET', '/platform/ipcountry');

  Future<dynamic> languages() => _transport.request('GET', '/platform/languages');

  Future<dynamic> botTypes() => _transport.request('GET', '/platform/bottypes');
}
