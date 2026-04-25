import '../transport.dart';

/// `client.ai` — AI credits + LLM analysis.
class Ai {
  final Transport _transport;
  Ai(this._transport);

  Future<dynamic> list({Map<String, dynamic>? params}) => _transport.request(
        'GET',
        '/ai/list',
        query: (params != null && params.isNotEmpty) ? params : null,
      );

  Future<dynamic> get(Object id) =>
      _transport.request('GET', '/ai/get', query: {'id': id});

  Future<dynamic> availableModels() =>
      _transport.request('GET', '/ai/availablemodels');

  // Credits.

  Future<dynamic> getCredits() => _transport.request('GET', '/ai/getaicredits');

  Future<dynamic> creditInvoices({Map<String, dynamic>? params}) => _transport.request(
        'GET',
        '/ai/aicreditinvoices',
        query: (params != null && params.isNotEmpty) ? params : null,
      );

  Future<dynamic> creditTransactions({Map<String, dynamic>? params}) => _transport.request(
        'GET',
        '/ai/aicredittransactions',
        query: (params != null && params.isNotEmpty) ? params : null,
      );

  Future<dynamic> buyCredits(Map<String, dynamic> data) =>
      _transport.request('POST', '/ai/buyaicredits', body: data);

  // LLM analysis.

  Future<dynamic> llmAnalyzeOptions() =>
      _transport.request('GET', '/ai/aillmanalyzeoptions');

  Future<dynamic> llmAnalyze(Map<String, dynamic> data) =>
      _transport.request('POST', '/ai/doaillmanalyze', body: data);

  Future<dynamic> llmAnalyzeResults({Map<String, dynamic>? params}) => _transport.request(
        'GET',
        '/ai/aillmanalyzeresults',
        query: (params != null && params.isNotEmpty) ? params : null,
      );

  Future<dynamic> llmResults({Map<String, dynamic>? params}) => _transport.request(
        'GET',
        '/ai/aillmresults',
        query: (params != null && params.isNotEmpty) ? params : null,
      );
}
