# Changelog

## 0.0.2

- **Features & Fixes**
  - Added custom error exception `TectaHttpException` and custom `ErrorParser` callback parameter to `TectaHttp`.
  - Added `maxLogs` limit to prevent memory leaks in production.
  - Added `MaskingUtil` to automatically sanitize and mask sensitive keys (e.g. passwords, tokens, cookies).
  - Fixed `ConnectivityStatus` to support safe execution on Flutter Web platforms.

## 0.0.1

- **Initial Release**
  - Added Tecta Inspector Core APIs (`TectaInspector`, `TectaHttp`).
  - Added draggable floating in-app inspector overlay button.
  - Added dynamic dark & light themes.
  - Added scrollable iOS Cupertino-style search/filter logs.
  - Added categorized logging categories: All, Print, Network, Database, and Navigator.
  - Added automatic unhandled exception and async error capturing with stack traces.
  - Added "Copy to Clipboard" with sleek custom Toast notifications.
  - Excluded external BLoC observers to be fully agnostic of state management.
