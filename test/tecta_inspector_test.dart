import 'package:flutter_test/flutter_test.dart';
import 'package:tecta_inspector/tecta_inspector.dart';

void main() {
  group('TcInspector.initialize', () {
    test('enables the inspector outside release mode', () {
      TcInspector.initialize(enabled: true);
      expect(TcInspector.enabled, isTrue);
    });

    test('stays disabled when not enabled', () {
      TcInspector.initialize(enabled: false, allowInReleaseMode: true);
      expect(TcInspector.enabled, isFalse);
    });
  });

  group('TcHttp validateStatus', () {
    test('keeps Dio default (2xx only) when not provided', () {
      final http = TcHttp(baseUrl: 'https://example.com', checkConnectivity: false);
      final validate = http.dio.options.validateStatus;
      expect(validate(200), isTrue);
      expect(validate(401), isFalse);
      expect(validate(500), isFalse);
    });

    test('uses the provided validateStatus', () {
      final http = TcHttp(
        baseUrl: 'https://example.com',
        checkConnectivity: false,
        validateStatus: (status) => status != null && status < 500,
      );
      final validate = http.dio.options.validateStatus;
      expect(validate(401), isTrue);
      expect(validate(500), isFalse);
    });
  });
}
