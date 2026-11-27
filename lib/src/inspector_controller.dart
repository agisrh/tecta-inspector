import 'package:flutter/widgets.dart';
import 'models/log_entry.dart';

class InspectorController {
  InspectorController._internal();
  static final InspectorController instance = InspectorController._internal();

  final ValueNotifier<List<LogEntry>> logsNotifier = ValueNotifier<List<LogEntry>>([]);

  int maxLogs = 150;

  List<LogEntry> get logs => logsNotifier.value;

  void addLog(LogEntry entry) {
    // Defer the value update to the next frame to avoid "setState() called during build" exceptions
    // if an error/exception is thrown and captured while Flutter is building the widget tree.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      var updatedList = [entry, ...logsNotifier.value];
      if (updatedList.length > maxLogs) {
        updatedList = updatedList.sublist(0, maxLogs);
      }
      logsNotifier.value = updatedList;
    });
    // A post-frame callback does not ask for a frame by itself. Without this
    // an entry added while the app is idle stays unseen until something draws.
    WidgetsBinding.instance.scheduleFrame();
  }

  void clearLogs() {
    logsNotifier.value = [];
  }
}
