/// Official Dart SDK for the Cryptohopper API.
///
/// ```dart
/// import 'package:cryptohopper/cryptohopper.dart';
///
/// final client = CryptohopperClient(
///   apiKey: Platform.environment['CRYPTOHOPPER_TOKEN']!,
/// );
///
/// final me = await client.user.get();
/// final ticker = await client.exchange.ticker(
///   exchange: 'binance',
///   market: 'BTC/USDT',
/// );
/// ```
library;

export 'src/client.dart' show CryptohopperClient;
export 'src/exception.dart' show CryptohopperException;
export 'src/version.dart' show sdkVersion;
