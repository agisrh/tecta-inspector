# Tc Inspector

A powerful, developer-friendly in-app debugging and logging tool for Flutter applications. It automatically intercepts network requests, captures console logs, monitors database operations, tracks page navigation, and auto-detects unhandled application errors—all accessible via a beautiful, reactive, floating in-app dashboard.

## Features

- 🎯 **Floating Inspector Button**: Access the dashboard anytime from anywhere. Fully reactive and automatically hides itself when the dashboard is open.
- 🎨 **Sleek Light/Dark Mode**: A beautiful, modern interface with responsive styles and dynamic dark/light mode toggle.
- 🌐 **Network Request Interception**: Automatically tracks API requests, status codes, request/response headers, parameters, and bodies using `TcHttp` and custom interceptors.
- 📦 **Categorized Logs Dashboard**: Filters log entries into 5 distinct categories:
  - **All**: Complete unified stream of all captured logs.
  - **Print**: Standard console prints and custom manual log messages.
  - **Network**: HTTP requests, responses, and API errors.
  - **Database**: SQL queries and custom database transactions.
  - **Navigator**: Route transitions (PUSH, POP, REPLACE) with arguments.
- 🛡️ **Auto-Catch Exceptions**: Automatically intercepts unhandled Flutter framework errors and asynchronous exceptions with stack traces.
- 📋 **Copy to Clipboard with Custom Toast**: Effortlessly copy log details or stack traces to the clipboard with an overlay notification.
- 🧩 **Zero Dependencies on BLoC**: Agnostic state management designed to fit into any codebase cleanly.

---

## Installation

Add `tecta_inspector` to your `pubspec.yaml`:

```yaml
dependencies:
  tecta_inspector: ^0.0.4
```

---

## Quick Start

### 1. Initialize Tc Inspector
Call `TcInspector.initialize` in your `main()` method before running the app. You can conditionally enable or disable it based on whether it is running in production.

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the inspector
  TcInspector.initialize(enabled: true);

  runApp(const MyApp());
}
```

The inspector is automatically disabled in release builds to protect sensitive network and log data. To keep it on in a release build (for example an internal QA or staging build), opt in explicitly:

```dart
TcInspector.initialize(enabled: true, allowInReleaseMode: true);
```

### 2. Configure MaterialApp & Overlay
Configure `MaterialApp` with the inspector's `navigatorKey`, add the observer to track routes, and wrap the widget tree inside `TcInspectorOverlay`.

```dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tc Inspector Example',
      navigatorKey: TcInspector.navigatorKey, // Required for pushing the dashboard
      navigatorObservers: [
        TcInspectorNavigatorObserver(), // Logs route transitions automatically
      ],
      builder: (context, child) {
        return TcInspectorOverlay(
          child: child ?? const SizedBox(), // Renders the floating debugger button
        );
      },
      home: const HomeScreen(),
    );
  }
}
```

---

## Usage Guide

### Network Logging
Use `TcHttp` as your main network client. It automatically integrates the `TcInspectorInterceptor` under the hood.

```dart
final http = TcHttp(baseUrl: 'https://api.example.com');

// Successful and failed HTTP calls are automatically logged to the Network tab!
final response = await http.call('/posts', method: MethodRequest.GET);
```

By default only 2xx responses are treated as successful; anything else throws a `TcHttpException`. To receive 4xx responses as normal `Response` objects instead, pass `validateStatus`:

```dart
final http = TcHttp(
  baseUrl: 'https://api.example.com',
  validateStatus: (status) => status != null && status < 500,
);
```

> Note: when 401 is treated as successful, `AuthInterceptor` will not refresh the token for that response.

### Manual Console Logs
Log regular strings or debug information directly to the **Print** tab:

```dart
TcInspector.log("User successfully clicked standard action button.");
```

### Custom Error Logging
Log manual exceptions or try-catch blocks:

```dart
try {
  // run some code
} catch (e, stack) {
  TcInspector.logError("Failed to complete transaction", error: e, stackTrace: stack);
}
```

### Database Logging
Log SQL queries or custom operations directly to the **Database** tab:

```dart
TcInspector.logDatabase(
  query: "SELECT * FROM users WHERE status = 'active';",
  result: "Found 12 active users",
);
```

---

## Additional Information

- **Auto-catch Exceptions**: Unhandled crashes or null-pointer exceptions will automatically pop up in the dashboard with their stack traces, highlighting issues in red.
- **Copying Logs**: Tap the **"Copy Log"** button inside any expanded log entry to instantly copy the raw content. A sleek overlay Toast will confirm the action.

## License

This package is licensed under the MIT License.
