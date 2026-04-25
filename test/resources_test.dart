import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import 'mock_backend.dart';

void main() {
  group('Resources — path & body wiring', () {
    late MockBackend backend;

    setUp(() {
      backend = MockBackend(
        List.generate(40, (_) => http.Response('{"data":[]}', 200)),
      );
    });

    test('hoppers.list hits /hopper/list', () async {
      await backend.client.hoppers.list();
      expect(backend.last.url.path, endsWith('/hopper/list'));
    });

    test('hoppers.configUpdate merges hopper_id into the body', () async {
      await backend.client.hoppers.configUpdate(42, {'dca': true});
      final body = backend.lastBodyJson()!;
      expect(body['hopper_id'], 42);
      expect(body['dca'], true);
    });

    test('exchange.forexRates uses the hyphenated path', () async {
      await backend.client.exchange.forexRates();
      expect(backend.last.url.path, endsWith('/exchange/forex-rates'));
    });

    test('strategy.list hits /strategy/strategies', () async {
      await backend.client.strategy.list();
      expect(backend.last.url.path, endsWith('/strategy/strategies'));
    });

    test('backtest.create hits /backtest/new', () async {
      await backend.client.backtest.create({'foo': 'bar'});
      expect(backend.last.url.path, endsWith('/backtest/new'));
    });

    test('market.items hits /market/marketitems', () async {
      await backend.client.market.items();
      expect(backend.last.url.path, endsWith('/market/marketitems'));
    });

    test('signals.chartData hits /signals/chartdata', () async {
      await backend.client.signals.chartData();
      expect(backend.last.url.path, endsWith('/signals/chartdata'));
    });

    test('arbitrage.marketCancel uses the hyphenated path', () async {
      await backend.client.arbitrage.marketCancel();
      expect(backend.last.url.path, endsWith('/arbitrage/market-cancel'));
    });

    test('arbitrage.deleteBacklog posts the backlog_id', () async {
      await backend.client.arbitrage.deleteBacklog('bl-1');
      expect(backend.lastBodyJson()!['backlog_id'], 'bl-1');
    });

    test('marketmaker.setMarketTrend uses the hyphenated path', () async {
      await backend.client.marketmaker.setMarketTrend({'trend': 'up'});
      expect(backend.last.url.path, endsWith('/marketmaker/set-market-trend'));
    });

    test('template.load sends both ids', () async {
      await backend.client.template.load(7, 99);
      final body = backend.lastBodyJson()!;
      expect(body['template_id'], 7);
      expect(body['hopper_id'], 99);
    });

    test('ai.llmAnalyze hits /ai/doaillmanalyze', () async {
      await backend.client.ai.llmAnalyze({'model': 'gpt-5'});
      expect(backend.last.url.path, endsWith('/ai/doaillmanalyze'));
    });

    test('ai.getCredits keeps the server-side prefix', () async {
      await backend.client.ai.getCredits();
      expect(backend.last.url.path, endsWith('/ai/getaicredits'));
    });

    test('platform.searchDocumentation passes q', () async {
      await backend.client.platform.searchDocumentation('dca');
      expect(backend.last.url.queryParameters['q'], 'dca');
    });

    test('chart.shareSave uses the hyphenated path', () async {
      await backend.client.chart.shareSave({'foo': 1});
      expect(backend.last.url.path, endsWith('/chart/share-save'));
    });

    test('subscription.stopSubscription posts an empty body', () async {
      await backend.client.subscription.stopSubscription();
      final body = backend.lastBodyJson();
      expect(body, isEmpty);
    });

    test('social.getConversation maps to /social/loadconversation', () async {
      await backend.client.social.getConversation('c-42');
      expect(backend.last.url.path, endsWith('/social/loadconversation'));
    });

    test('social.createPost maps to bare /social/post', () async {
      await backend.client.social.createPost({'text': 'hi'});
      expect(backend.last.url.path, endsWith('/social/post'));
    });

    test('tournaments.list hits /tournaments/gettournaments', () async {
      await backend.client.tournaments.list();
      expect(backend.last.url.path, endsWith('/tournaments/gettournaments'));
    });

    test('tournaments.tournamentLeaderboard underscored', () async {
      await backend.client.tournaments.tournamentLeaderboard(9);
      expect(backend.last.url.path, endsWith('/tournaments/leaderboard_tournament'));
    });

    test('user.get hits /user/get', () async {
      await backend.client.user.get();
      expect(backend.last.url.path, endsWith('/user/get'));
    });

    test('webhooks.create posts to /api/webhook_create', () async {
      await backend.client.webhooks.create({'url': 'https://example.com/hook'});
      expect(backend.last.url.path, endsWith('/api/webhook_create'));
    });

    test('app.inAppPurchase underscored', () async {
      await backend.client.app.inAppPurchase({'receipt': 'abc'});
      expect(backend.last.url.path, endsWith('/app/in_app_purchase'));
    });

    test('template.save hits /template/save-template', () async {
      await backend.client.template.save({'foo': 1});
      expect(backend.last.url.path, endsWith('/template/save-template'));
    });

    test('strategy.update hits /strategy/edit', () async {
      await backend.client.strategy.update(3, {'name': 'foo'});
      expect(backend.last.url.path, endsWith('/strategy/edit'));
    });
  });
}
