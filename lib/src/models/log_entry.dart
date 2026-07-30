enum LogType {
  all,
  print,
  network,
  database,
  navigator,
}

class LogEntry {
  final String id;
  final DateTime timestamp;
  final LogType type;
  final String title;
  final String content;
  final String? error;
  final String? stackTrace;
  final Map<String, dynamic>? metadata;
  final bool isError;

  LogEntry({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.title,
    required this.content,
    this.error,
    this.stackTrace,
    this.metadata,
    this.isError = false,
  });
}
