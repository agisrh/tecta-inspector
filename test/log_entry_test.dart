import 'package:flutter_test/flutter_test.dart';
import 'package:tecta_inspector/src/curl_builder.dart';
import 'package:tecta_inspector/tecta_inspector.dart';

LogEntry _entry({
  LogType type = LogType.print,
  String title = 'title',
  String content = 'content',
  bool isError = false,
  String? error,
  Map<String, dynamic>? metadata,
}) =>
    LogEntry(
      id: '1',
      timestamp: DateTime(2026),
      type: type,
      title: title,
      content: content,
      isError: isError,
      error: error,
      metadata: metadata,
    );

void main() {
  group('isFailure', () {
    test('is true for an error log', () {
      expect(_entry(isError: true).isFailure, isTrue);
    });

    test('is true for a response of 400 or more, even without an error', () {
      expect(
          _entry(type: LogType.network, metadata: {'statusCode': 404})
              .isFailure,
          isTrue);
      expect(
          _entry(type: LogType.network, metadata: {'statusCode': 200})
              .isFailure,
          isFalse);
      expect(
          _entry(type: LogType.network, metadata: {'statusCode': null})
              .isFailure,
          isFalse);
    });
  });

  group('matches', () {
    test('finds the query in the title, content, error and metadata', () {
      final log = _entry(
        title: 'GET /orders',
        content: 'body',
        error: 'Timeout',
        metadata: {'result': '3 rows'},
      );

      expect(log.matches('orders'), isTrue);
      expect(log.matches('body'), isTrue);
      expect(log.matches('timeout'), isTrue);
      expect(log.matches('3 rows'), isTrue);
      expect(log.matches('missing'), isFalse);
    });

    test('matches everything when the query is empty', () {
      expect(_entry().matches(''), isTrue);
    });
  });

  group('buildCurl', () {
    test('builds a command from the method, url, headers and body', () {
      final curl = buildCurl(_entry(type: LogType.network, metadata: {
        'method': 'POST',
        'url': 'https://api.test/login',
        'requestHeaders': {'Content-Type': 'application/json'},
        'requestBody': {'username': 'demo'},
      }));

      expect(
        curl,
        "curl -X POST 'https://api.test/login' -H 'Content-Type: application/json' "
        "--data-raw '{\"username\":\"demo\"}'",
      );
    });

    test('quotes a single quote inside a value', () {
      final curl = buildCurl(_entry(type: LogType.network, metadata: {
        'method': 'POST',
        'url': 'https://api.test/x',
        'requestBody': "it's",
      }));

      expect(curl, contains(r"'it'\''s'"));
    });

    test('leaves out an empty body and returns null for a non-network log', () {
      final get = buildCurl(_entry(type: LogType.network, metadata: {
        'method': 'GET',
        'url': 'https://api.test/x',
        'requestBody': null,
      }));

      expect(get, "curl -X GET 'https://api.test/x'");
      expect(buildCurl(_entry()), isNull);
    });
  });
}
