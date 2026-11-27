import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tecta_inspector/tecta_inspector.dart';

/// An adapter that cannot reach the server and counts how often it is asked.
class _Unreachable implements HttpClientAdapter {
  int attempts = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    attempts++;
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.connectionError,
      message: 'unreachable',
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _Unreachable adapter;

  TcHttp client({bool retryNonIdempotent = false}) {
    adapter = _Unreachable();
    return TcHttp(
      baseUrl: 'https://api.test',
      checkConnectivity: false,
      retryNonIdempotent: retryNonIdempotent,
      dio: Dio()..httpClientAdapter = adapter,
    );
  }

  /// Makes the call, lets the retry delays pass (1, 2 and 3 seconds) and
  /// reports how many times the server was asked.
  Future<int> attemptsOf(
    WidgetTester tester,
    Future<Response> Function(TcHttp http) call, {
    TcHttp? http,
  }) async {
    final target = http ?? client();
    call(target).ignore();
    await tester.pump(const Duration(seconds: 10));
    return adapter.attempts;
  }

  testWidgets('a failed GET is tried again, up to three more times',
      (tester) async {
    final attempts = await attemptsOf(
      tester,
      (http) => http.call('items', method: MethodRequest.GET),
    );

    expect(attempts, 4);
  });

  testWidgets('a failed PUT or DELETE is tried again too: both are idempotent',
      (tester) async {
    expect(
      await attemptsOf(
        tester,
        (http) => http.call('items/1', method: MethodRequest.PUT),
      ),
      4,
    );
    expect(
      await attemptsOf(
        tester,
        (http) => http.call('items/1', method: MethodRequest.DELETE),
      ),
      4,
    );
  });

  testWidgets('a failed POST is sent only once by default', (tester) async {
    final attempts = await attemptsOf(
      tester,
      (http) => http.call('login', request: {'user': 'demo'}),
    );

    expect(attempts, 1);
  });

  testWidgets('retryNonIdempotent brings the retry of a POST back',
      (tester) async {
    final attempts = await attemptsOf(
      tester,
      (http) => http.call('search', request: {'q': 'a'}),
      http: client(retryNonIdempotent: true),
    );

    expect(attempts, 4);
  });

  testWidgets('a call can opt out of the retry with disableRetry',
      (tester) async {
    final attempts = await attemptsOf(
      tester,
      (http) => http.call(
        'items',
        method: MethodRequest.GET,
        options: Options()..disableRetry = true,
      ),
    );

    expect(attempts, 1);
  });

  test('disableRetry keeps the options the caller already set', () {
    final options = Options(headers: {'X-Test': '1'})..disableRetry = true;

    expect(options.headers?['X-Test'], '1');
    expect(options.disableRetry, isTrue);
    expect(Options().disableRetry, isFalse);
  });
}
