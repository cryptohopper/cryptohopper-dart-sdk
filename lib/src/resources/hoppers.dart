import '../transport.dart';

/// `client.hoppers` — user trading bots (CRUD, positions, orders, trade, config).
class Hoppers {
  final Transport _transport;
  Hoppers(this._transport);

  Future<dynamic> list({String? exchange}) => _transport.request(
        'GET',
        '/hopper/list',
        query: exchange != null ? {'exchange': exchange} : null,
      );

  Future<dynamic> get(Object hopperId) => _transport.request(
        'GET',
        '/hopper/get',
        query: {'hopper_id': hopperId},
      );

  Future<dynamic> create(Map<String, dynamic> data) =>
      _transport.request('POST', '/hopper/create', body: data);

  Future<dynamic> update(Object hopperId, Map<String, dynamic> data) =>
      _transport.request('POST', '/hopper/update', body: {'hopper_id': hopperId, ...data});

  Future<dynamic> delete(Object hopperId) =>
      _transport.request('POST', '/hopper/delete', body: {'hopper_id': hopperId});

  Future<dynamic> positions(Object hopperId) => _transport.request(
        'GET',
        '/hopper/positions',
        query: {'hopper_id': hopperId},
      );

  Future<dynamic> position(Object hopperId, Object positionId) => _transport.request(
        'GET',
        '/hopper/position',
        query: {'hopper_id': hopperId, 'position_id': positionId},
      );

  Future<dynamic> orders(Object hopperId, {Map<String, dynamic>? extra}) => _transport.request(
        'GET',
        '/hopper/orders',
        query: {'hopper_id': hopperId, ...?extra},
      );

  Future<dynamic> buy(Map<String, dynamic> data) =>
      _transport.request('POST', '/hopper/buy', body: data);

  Future<dynamic> sell(Map<String, dynamic> data) =>
      _transport.request('POST', '/hopper/sell', body: data);

  Future<dynamic> configGet(Object hopperId) =>
      _transport.request('GET', '/hopper/configget', query: {'hopper_id': hopperId});

  Future<dynamic> configUpdate(Object hopperId, Map<String, dynamic> config) =>
      _transport.request('POST', '/hopper/configupdate', body: {'hopper_id': hopperId, ...config});

  Future<dynamic> configPools(Object hopperId) =>
      _transport.request('GET', '/hopper/configpools', query: {'hopper_id': hopperId});

  Future<dynamic> panic(Object hopperId) =>
      _transport.request('POST', '/hopper/panic', body: {'hopper_id': hopperId});
}
