import '../transport.dart';

/// `client.user` — authenticated user profile.
class User {
  final Transport _transport;
  User(this._transport);

  /// Fetch the authenticated user's profile. Requires `user` scope.
  Future<dynamic> get() => _transport.request('GET', '/user/get');
}
