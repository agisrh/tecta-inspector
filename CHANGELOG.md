# Changelog

## 0.0.5

- **Behaviour change: masking**
  - A key is now masked when the words of a masked key appear among the words of the field name. Words are split on case changes and on anything that is not a letter or digit, so `fcmToken`, `access_token` and `refresh-token` match `token`, while `shipping` and `mapping` no longer match `pin`. Keys passed to `TcInspector.initialize(maskedKeys: ...)` follow the same rule.
  - Card numbers are masked only when the digits pass the Luhn check, so millisecond timestamps and similar numbers are left alone.
  - `captcha` and `otp` are masked by default.
  - Added `MaskingUtil.isMaskedKey`.

- **UI**
  - The dashboard title reads "Inspector" instead of "Tc Inspector".
  - The app bar keeps one colour while the list scrolls under it. Before, Material 3 tinted it and the search field was hard to tell apart from the bar.
  - The theme (dark or light) is kept while the app runs, so reopening the dashboard does not reset it.
  - The search field is 44 logical pixels high, and its clear button has a 44 pixel touch area.
  - The search also looks in the error and in every metadata value, such as a database `result`.
  - New **Errors** chip next to the search field. It shows how many failures there are (error logs and responses with status 400 or more) and, when selected, lists only those.
  - Each tab shows how many entries it holds in a small rounded badge, for example `Network` with a `12` badge.
  - The empty state tells apart "No logs yet", "No logs match \"query\"" (with a **Clear search** button), "No errors here" and "Nothing in this tab yet".
  - The **Errors** chip is red while there are failures and muted when there are none, filled when it is on, and its number sits in the same rounded badge the tabs use.
  - A network row ends its time line with the **duration** (`08:05:09.042 • NETWORK • 128 ms`). Times show milliseconds. The title already carries the method and the status.
  - An opened network log is split into foldable sections: **Summary**, **Error**, **Request body**, **Response body**, **Request headers** (folded) and **Raw log** (folded).
  - Bodies are indented and coloured (keys, strings, numbers and keywords), and a body longer than 40 lines shows a **Show all** button. Individual JSON nodes cannot be folded.
  - A stack trace dims the frames of the Dart SDK and common framework packages, so the app's own frames stand out. Which packages count as framework is a fixed list.
  - The search text is highlighted in the title of each match.
  - Network logs have **Copy cURL** and **Copy Response** next to **Copy Log**. The cURL command uses the masked headers and body the inspector stores, so fill in secrets before running it.

- **API**
  - `LogEntry.isFailure` and `LogEntry.matches(query)`.

- **Fixes**
  - A failed network call is titled with its status code (`POST /login - 401`), like a successful one. Only a call without any response, such as a timeout, is titled `Error`.
  - Text on the light theme is readable: times, labels, section titles and the JSON colours, the status colours and the Errors chip all reach a contrast ratio of 4.5 or more on the row backgrounds. Tests check this.
  - A log added while the app is idle now requests a frame, so it shows up at once instead of waiting for something else to draw.

## 0.0.4

- **Features**
  - Added `allowInReleaseMode` to `TcInspector.initialize`. The inspector stays force-disabled in release mode by default; pass `allowInReleaseMode: true` to keep it on for internal QA or staging release builds.
  - Added an optional `validateStatus` parameter to `TcHttp` to customize which HTTP status codes are treated as successful. Defaults to Dio's behaviour (2xx only), so 4xx/5xx still raise `TcHttpException` and 401 responses still trigger `AuthInterceptor` token refresh.

- **Docs**
  - Updated the installation guide to use the pub.dev dependency.

## 0.0.3

- **Features & Performance Optimizations**
  - Implemented robust request queueing/locks in `AuthInterceptor` to prevent race conditions during concurrent unauthorized (401) API requests.
  - Added payload string truncation (up to 20,000 characters) in `TcInspectorInterceptor` to limit memory usage for extremely large payloads.
  - Enhanced `MaskingUtil` to support RegExp pattern censoring (detecting JWT, Bearer Token, Basic Auth, and Credit Cards) alongside deep-key traversal.

- **Critical Fixes & Security Updates**
  - Fixed request queue hang issue in `AuthInterceptor` when the refresh token provider returns a null or empty token.
  - Automatically force disable `TectaInspector` when running in Release Mode (`kReleaseMode == true`) to protect sensitive application log and network data in production.

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
