# Changelog

## 0.0.4

- **Critical Fixes & Security Updates**
  - Fixed request queue hang issue in `AuthInterceptor` when the refresh token provider returns a null or empty token.
  - Automatically force disable `TectaInspector` when running in Release Mode (`kReleaseMode == true`) to protect sensitive application log and network data in production.

## 0.0.3

- **Features & Performance Optimizations**
  - Implemented robust request queueing/locks in `AuthInterceptor` to prevent race conditions during concurrent unauthorized (401) API requests.
  - Added payload string truncation (up to 20,000 characters) in `TcInspectorInterceptor` to limit memory usage for extremely large payloads.
  - Enhanced `MaskingUtil` to support RegExp pattern censoring (detecting JWT, Bearer Token, Basic Auth, and Credit Cards) alongside deep-key traversal.

## 0.0.2

- **Features & Fixes**
  - Added custom error exception `TcHttpException` and custom `ErrorParser` callback parameter to `TcHttp`.
  - Added `maxLogs` limit to prevent memory leaks in production.
  - Added `MaskingUtil` to automatically sanitize and mask sensitive keys (e.g. passwords, tokens, cookies).
  - Fixed `ConnectivityStatus` to support safe execution on Flutter Web platforms.

## 0.0.1

- **Initial Release**
  - Added Tc Inspector Core APIs (`TcInspector`, `TcHttp`).
  - Added draggable floating in-app inspector overlay button.
  - Added dynamic dark & light themes.
  - Added scrollable iOS Cupertino-style search/filter logs.
  - Added categorized logging categories: All, Print, Network, Database, and Navigator.
  - Added automatic unhandled exception and async error capturing with stack traces.
  - Added "Copy to Clipboard" with sleek custom Toast notifications.
  - Excluded external BLoC observers to be fully agnostic of state management.
