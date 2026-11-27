import 'dart:convert';

import 'models/log_entry.dart';

/// Builds a `curl` command for a network log, or null when the entry has no
/// request to repeat.
///
/// The headers and the body are the masked ones the inspector stores, so
/// secrets show as `*** [MASKED] ***` and must be filled in before it is run.
String? buildCurl(LogEntry log) {
  final metadata = log.metadata;
  final url = metadata?['url'];
  final method = metadata?['method'];
  if (log.type != LogType.network || url is! String || method is! String) return null;

  final parts = <String>['curl', '-X', method, _quote(url)];
  final headers = metadata?['requestHeaders'];
  if (headers is Map) {
    headers.forEach((name, value) => parts.addAll(['-H', _quote('$name: $value')]));
  }
  final body = metadata?['requestBody'];
  if (body != null && !(body is Map && body.isEmpty) && !(body is String && body.isEmpty)) {
    parts.addAll(['--data-raw', _quote(body is String ? body : jsonEncode(body))]);
  }
  return parts.join(' ');
}

String _quote(String value) => "'${value.replaceAll("'", r"'\''")}'";
