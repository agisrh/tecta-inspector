import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'models/log_entry.dart';
import 'inspector_controller.dart';
import 'masking_util.dart';

class TcInspector {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static final ValueNotifier<bool> enabledNotifier = ValueNotifier<bool>(false);
  static final ValueNotifier<bool> isDashboardOpen = ValueNotifier<bool>(false);

  static bool get enabled => enabledNotifier.value;

  /// Initialize the inspector's enabled/disabled status
  ///
  /// The inspector is forced off in release mode to protect sensitive
  /// network/log data. Set [allowInReleaseMode] to `true` to opt out of that
  /// protection, e.g. for internal QA or staging builds.
  static void initialize({
    bool enabled = false,
    bool allowInReleaseMode = false,
    int maxLogs = 150,
    List<String>? maskedKeys,
  }) {
    enabledNotifier.value = enabled && (!kReleaseMode || allowInReleaseMode);
    InspectorController.instance.maxLogs = maxLogs;
    if (maskedKeys != null) {
      MaskingUtil.maskedKeys = maskedKeys;
    }

    if (enabledNotifier.value) {
      // Automatically catch unhandled Flutter framework errors
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        final exceptionStr = details.exceptionAsString();
        final stackStr = details.stack?.toString() ?? '';

        // Prevent infinite cross-frame logging loops if the error occurs in our own package code
        if (exceptionStr.contains('tecta_inspector') || stackStr.contains('tecta_inspector')) {
          originalOnError?.call(details);
          return;
        }

        logError(
          'Unhandled Flutter Error',
          error: exceptionStr,
          stackTrace: details.stack,
        );
        originalOnError?.call(details);
      };

      // Automatically catch unhandled asynchronous Dart errors
      final originalPlatformOnError = PlatformDispatcher.instance.onError;
      PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
        final errorStr = error.toString();
        final stackStr = stack.toString();

        // Prevent infinite cross-frame logging loops if the error occurs in our own package code
        if (errorStr.contains('tecta_inspector') || stackStr.contains('tecta_inspector')) {
          if (originalPlatformOnError != null) {
            return originalPlatformOnError(error, stack);
          }
          return false;
        }

        logError(
          'Unhandled Async Error',
          error: errorStr,
          stackTrace: stack,
        );
        if (originalPlatformOnError != null) {
          return originalPlatformOnError(error, stack);
        }
        return false;
      };
    }
  }

  /// Add a general log (PRINT category)
  static void log(String message, {Map<String, dynamic>? metadata}) {
    if (!enabled) return;
    final entry = LogEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      type: LogType.print,
      title: 'Console Print',
      content: message,
      metadata: metadata,
    );
    InspectorController.instance.addLog(entry);
  }

  static bool _isLoggingError = false;

  /// Add an error log (PRINT/ERROR category)
  static void logError(
    String title, {
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) {
    if (!enabled) return;
    if (_isLoggingError) return;
    _isLoggingError = true;
    try {
      final entry = LogEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        timestamp: DateTime.now(),
        type: LogType.print,
        title: title,
        content: error?.toString() ?? 'Unknown error occurred',
        error: error?.toString(),
        stackTrace: stackTrace?.toString(),
        metadata: metadata,
        isError: true,
      );
      InspectorController.instance.addLog(entry);
    } catch (_) {
      // Avoid letting error logging fail and throw exceptions back into handlers
    } finally {
      _isLoggingError = false;
    }
  }

  /// Add a database operation log (DATABASE category)
  static void logDatabase({
    required String query,
    String? result,
    Map<String, dynamic>? metadata,
  }) {
    if (!enabled) return;
    final entry = LogEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      type: LogType.database,
      title: 'Database Query',
      content: query,
      metadata: {
        if (result != null) 'result': result,
        if (metadata != null) ...metadata,
      },
    );
    InspectorController.instance.addLog(entry);
  }

  /// Add a log entry directly using LogEntry
  static void addLogEntry(LogEntry entry) {
    if (!enabled) return;
    InspectorController.instance.addLog(entry);
  }

  /// Clear all logs
  static void clearLogs() {
    InspectorController.instance.clearLogs();
  }
}
