// ignore_for_file: avoid_print
import 'dart:io';

import 'package:cryptohopper/cryptohopper.dart';

Future<void> main() async {
  final token = Platform.environment['CRYPTOHOPPER_TOKEN'];
  if (token == null || token.isEmpty) {
    stderr.writeln('Set CRYPTOHOPPER_TOKEN before running this example.');
    exit(1);
  }

  final client = CryptohopperClient(apiKey: token);

  try {
    final me = await client.user.get() as Map<String, dynamic>;
    print('User: ${me['email'] ?? me['username'] ?? me['id']}');

    final ticker = await client.exchange.ticker(
      exchange: 'binance',
      market: 'BTC/USDT',
    ) as Map<String, dynamic>;
    print('BTC/USDT on binance: last=${ticker['last']}, bid=${ticker['bid']}, ask=${ticker['ask']}');

    final hoppers = await client.hoppers.list() as List<dynamic>;
    print('You have ${hoppers.length} hopper(s).');
  } on CryptohopperException catch (e) {
    stderr.writeln('${e.code} (${e.status}): ${e.message}');
    if (e.ipAddress != null) stderr.writeln('  IP: ${e.ipAddress}');
    exit(1);
  } finally {
    client.close();
  }
}
