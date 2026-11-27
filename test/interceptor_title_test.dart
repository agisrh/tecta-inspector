import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tecta_inspector/src/inspector_controller.dart';
import 'package:tecta_inspector/src/tecta_inspector_interceptor.dart';
import 'package:tecta_inspector/tecta_inspector.dart';

void main() {
  setUp(() {
    TcInspector.initialize(enabled: true);
    TcInspector.clearLogs();
  });

  Future<String> titleOfFailure(WidgetTester tester, {int? status}) async {
    final options = RequestOptions(
        path: '/login', method: 'POST', baseUrl: 'https://api.test');
    final error = DioException(
      requestOptions: options,
      type: status == null
          ? DioExceptionType.connectionTimeout
          : DioExceptionType.badResponse,
      response: status == null
          ? null
          : Response(
              requestOptions: options,
              statusCode: status,
              data: {'message': 'no'}),
    );

    final handler = ErrorInterceptorHandler();
    // Passing the error on completes the handler's future with an error that
    // nothing listens to here.
    // ignore: invalid_use_of_protected_member
    unawaited(handler.future.then<void>((_) {}, onError: (_) {}));
    TcInspectorInterceptor().onError(error, handler);
    await tester.pump();
    return InspectorController.instance.logs.single.title;
  }

  testWidgets(
      'a failed call is titled with its status code, like a successful one',
      (tester) async {
    expect(await titleOfFailure(tester, status: 401), 'POST /login - 401');
  });

  testWidgets('a failed call without a response is titled Error',
      (tester) async {
    expect(await titleOfFailure(tester), 'POST /login - Error');
  });
}
