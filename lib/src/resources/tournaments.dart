import '../transport.dart';

/// `client.tournaments` — trading competitions.
class Tournaments {
  final Transport _transport;
  Tournaments(this._transport);

  Future<dynamic> list({Map<String, dynamic>? params}) => _transport.request(
        'GET',
        '/tournaments/gettournaments',
        query: (params != null && params.isNotEmpty) ? params : null,
      );

  Future<dynamic> active() => _transport.request('GET', '/tournaments/active');

  Future<dynamic> get(Object tournamentId) => _transport.request(
        'GET',
        '/tournaments/gettournament',
        query: {'tournament_id': tournamentId},
      );

  Future<dynamic> search(String query) =>
      _transport.request('GET', '/tournaments/search', query: {'q': query});

  Future<dynamic> trades(Object tournamentId) => _transport.request(
        'GET',
        '/tournaments/trades',
        query: {'tournament_id': tournamentId},
      );

  Future<dynamic> stats(Object tournamentId) => _transport.request(
        'GET',
        '/tournaments/stats',
        query: {'tournament_id': tournamentId},
      );

  Future<dynamic> activity(Object tournamentId) => _transport.request(
        'GET',
        '/tournaments/activity',
        query: {'tournament_id': tournamentId},
      );

  Future<dynamic> leaderboard({Map<String, dynamic>? params}) => _transport.request(
        'GET',
        '/tournaments/leaderboard',
        query: (params != null && params.isNotEmpty) ? params : null,
      );

  Future<dynamic> tournamentLeaderboard(Object tournamentId) => _transport.request(
        'GET',
        '/tournaments/leaderboard_tournament',
        query: {'tournament_id': tournamentId},
      );

  Future<dynamic> join(Object tournamentId, {Map<String, dynamic>? data}) =>
      _transport.request('POST', '/tournaments/join', body: {
        'tournament_id': tournamentId,
        ...?data,
      });

  Future<dynamic> leave(Object tournamentId) => _transport.request(
        'POST',
        '/tournaments/leave',
        body: {'tournament_id': tournamentId},
      );
}
