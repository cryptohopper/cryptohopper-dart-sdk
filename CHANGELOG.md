# Changelog

All notable changes to `cryptohopper` are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project
adheres to [Semantic Versioning](https://semver.org/).

## 0.1.0-alpha.1 — 2026-04-25

Initial alpha release. Full coverage of all 18 public API domains from day one.

### Added

- `CryptohopperClient` — async client built on `package:http`, with typed exceptions, auto-retry on HTTP 429, and a bring-your-own [`http.Client`] option for tests.
- `CryptohopperException` — single exception type whose `code` follows the shared SDK taxonomy (`UNAUTHORIZED`, `FORBIDDEN`, `NOT_FOUND`, `RATE_LIMITED`, `VALIDATION_ERROR`, `DEVICE_UNAUTHORIZED`, `CONFLICT`, `SERVER_ERROR`, `SERVICE_UNAVAILABLE`, `NETWORK_ERROR`, `TIMEOUT`, `UNKNOWN`).
- Auto-retry on HTTP 429 honouring `Retry-After`; default `maxRetries: 3`, disableable via `maxRetries: 0`.
- Resource classes: `user`, `hoppers`, `exchange`, `strategy`, `backtest`, `market`, `signals`, `arbitrage`, `marketmaker`, `template`, `ai`, `platform`, `chart`, `subscription`, `social`, `tournaments`, `webhooks`, `app`.
- `package:test` suite covering client construction, error mapping, retry behaviour, and resource path/body wiring across all 18 domains.
