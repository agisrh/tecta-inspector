import 'package:flutter/widgets.dart';
import 'models/log_entry.dart';

class InspectorController {
  InspectorController._internal();
  static final InspectorController instance = InspectorController._internal();

  final ValueNotifier<List<LogEntry>> logsNotifier = ValueNotifier<List<LogEntry>>([]);

  List<LogEntry> get logs => logsNotifier.value;

  void addLog(LogEntry entry) {
    // Defer the value update to the next frame to avoid "setState() called during build" exceptions
    // if an error/exception is thrown and captured while Flutter is building the widget tree.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      logsNotifier.value = [entry, ...logsNotifier.value];
    });
  }

  void clearLogs() {
    logsNotifier.value = [];
  }
}
