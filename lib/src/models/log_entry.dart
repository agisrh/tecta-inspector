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

  /// Whether this entry reports a failure: an error log, or a response whose
  /// status code is 400 or more.
  bool get isFailure {
    if (isError) return true;
    final status = metadata?['statusCode'];
    return status is int && status >= 400;
  }

  /// Whether the title, the content, the error or any metadata value holds
  /// [lowerCaseQuery]. An empty query matches everything.
  bool matches(String lowerCaseQuery) {
    if (lowerCaseQuery.isEmpty) return true;
    bool has(String? text) => text != null && text.toLowerCase().contains(lowerCaseQuery);
    if (has(title) || has(content) || has(error)) return true;
    return metadata?.values.any((value) => has('$value')) ?? false;
  }

  /// The HTTP method of a network log, when it has one.
  String? get method => metadata?['method'] is String ? metadata!['method'] as String : null;

  /// The HTTP status code of a network log, when it got a response.
  int? get statusCode => metadata?['statusCode'] is int ? metadata!['statusCode'] as int : null;

  /// How long a network call took, in milliseconds.
  int? get durationMs => metadata?['duration'] is int ? metadata!['duration'] as int : null;
}
