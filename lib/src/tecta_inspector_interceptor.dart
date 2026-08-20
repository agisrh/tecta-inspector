import 'dart:convert';
import 'package:dio/dio.dart';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'tecta_inspector_facade.dart';
import 'models/log_entry.dart';
import 'masking_util.dart';

enum Level { debug, info, warning, error, alien }

void logDebug(String message, {Level level = Level.info}) {
  const String resetColor = '\x1B[0m';
  const String redColor = '\x1B[31m';
  const String greenColor = '\x1B[32m';
  const String yellowColor = '\x1B[33m';
  const String cyanColor = '\x1B[36m';

  final now = DateTime.now();
  final timeString =
      '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

  if (kDebugMode) {
    try {
      String logMessage;
      switch (level) {
        case Level.debug:
          logMessage = '$cyanColor[DEBUG][$timeString] $message$resetColor';
          break;
        case Level.info:
          logMessage = '$greenColor[INFO][$timeString] $message$resetColor';
          break;
        case Level.warning:
          logMessage = '$yellowColor[WARNING][$timeString] $message $resetColor';
          break;
        case Level.error:
          logMessage = '$redColor[ERROR][$timeString] $message $resetColor';
          break;
        case Level.alien:
          logMessage = '$redColor[ALIEN][$timeString] $message $resetColor';
          break;
      }
      developer.log(logMessage);
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}

class TcInspectorInterceptor extends Interceptor {
  TcInspectorInterceptor({
    this.logRequestUrl = true,
    this.logRequestHeader = false,
    this.logRequestBody = false,
    this.logResponseHeader = false,
    this.logResponseBody = true,
    this.logResponseError = true,
  });

  final bool logRequestUrl;
  final bool logRequestHeader;
  final bool logRequestBody;
  final bool logResponseBody;
  final bool logResponseHeader;
  final bool logResponseError;

  final _startTimeKey = 'ro_start_time';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startTimeKey] = DateTime.now().millisecondsSinceEpoch;

    final requestPath = '${options.baseUrl}${options.path}';
    final currentLogRequestUrl = options.extra['logRequestUrl'] ?? logRequestUrl;
    final currentLogRequestHeader = options.extra['logRequestHeader'] ?? logRequestHeader;
    final currentLogRequestBody = options.extra['logRequestBody'] ?? logRequestBody;

    final maskedHeaders = MaskingUtil.mask(options.headers);
    final maskedData = MaskingUtil.mask(options.data);

    if (currentLogRequestUrl) {
      logDebug('onRequest: ${options.method} request => $requestPath', level: Level.info);
    }
    if (currentLogRequestHeader) {
      logDebug('onRequest: Request Headers => $maskedHeaders', level: Level.info);
    }
    if (currentLogRequestBody) {
      logDebug('onRequest: Request Data => ${_prettyJsonEncode(maskedData)}', level: Level.info);
    }

    return super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final options = response.requestOptions;
    final currentLogResponseBody = options.extra['logResponseBody'] ?? logResponseBody;
    final currentLogResponseHeader = options.extra['logResponseHeader'] ?? logResponseHeader;

    final responseHeadersMap = <String, dynamic>{};
    response.headers.forEach((name, values) {
      responseHeadersMap[name] = values;
    });
    final maskedResponseHeaders = MaskingUtil.mask(responseHeadersMap);
    final maskedResponseBody = MaskingUtil.mask(response.data);

    if (currentLogResponseHeader) {
      logDebug('onResponse: Response Headers => $maskedResponseHeaders', level: Level.debug);
    }
    if (currentLogResponseBody) {
      logDebug(
          'onResponse: StatusCode: ${response.statusCode}, Data: ${_prettyJsonEncode(maskedResponseBody)}',
          level: Level.debug);
    }

    // Record network log to TcInspector
    if (TcInspector.enabled) {
      final startTime = options.extra[_startTimeKey] as int?;
      final duration = startTime != null ? DateTime.now().millisecondsSinceEpoch - startTime : 0;

      final maskedRequestHeaders = MaskingUtil.mask(options.headers);
      final maskedRequestData = MaskingUtil.mask(options.data);
      final maskedQueryParameters = MaskingUtil.mask(options.queryParameters);

      final contentBuffer = StringBuffer();
      contentBuffer.writeln('Method: ${options.method}');
      contentBuffer.writeln('URL: ${options.uri}');
      contentBuffer.writeln('Duration: ${duration}ms');
      contentBuffer.writeln('Status Code: ${response.statusCode}');
      contentBuffer.writeln('\n[Headers]\n${_prettyJsonEncode(maskedRequestHeaders)}');
      if (options.queryParameters.isNotEmpty) {
        contentBuffer
            .writeln('\n[Query Parameters]\n${_prettyJsonEncode(maskedQueryParameters)}');
      }
      contentBuffer.writeln('\n[Request Body]\n${_prettyJsonEncode(maskedRequestData)}');
      contentBuffer.writeln('\n[Response Body]\n${_prettyJsonEncode(maskedResponseBody)}');

      TcInspector.addLogEntry(LogEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        timestamp: DateTime.now(),
        type: LogType.network,
        title: '${options.method} ${options.path} - ${response.statusCode}',
        content: contentBuffer.toString(),
        metadata: {
          'method': options.method,
          'url': options.uri.toString(),
          'statusCode': response.statusCode,
          'duration': duration,
          'requestHeaders': maskedRequestHeaders,
          'requestBody': maskedRequestData,
          'responseBody': maskedResponseBody,
        },
      ));
    }

    return super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final options = err.requestOptions;
    final requestPath = '${options.baseUrl}${options.path}';
    final currentLogResponseError = options.extra['logResponseError'] ?? logResponseError;

    if (currentLogResponseError) {
      logDebug('onError: ${options.method} request => $requestPath', level: Level.error);
      logDebug('onError: ${err.error}, Message: ${err.message}', level: Level.debug);
    }

    // Record network error log to TcInspector
    if (TcInspector.enabled) {
      final startTime = options.extra[_startTimeKey] as int?;
      final duration = startTime != null ? DateTime.now().millisecondsSinceEpoch - startTime : 0;

      final maskedRequestHeaders = MaskingUtil.mask(options.headers);
      final maskedRequestData = MaskingUtil.mask(options.data);
      final maskedResponseErrorBody = MaskingUtil.mask(err.response?.data);

      final contentBuffer = StringBuffer();
      contentBuffer.writeln('Method: ${options.method}');
      contentBuffer.writeln('URL: ${options.uri}');
      contentBuffer.writeln('Duration: ${duration}ms');
      contentBuffer.writeln('Error Type: ${err.type}');
      contentBuffer.writeln('Status Code: ${err.response?.statusCode}');
      contentBuffer.writeln('Error Message: ${err.message}');
      contentBuffer.writeln('\n[Headers]\n${_prettyJsonEncode(maskedRequestHeaders)}');
      contentBuffer.writeln('\n[Request Body]\n${_prettyJsonEncode(maskedRequestData)}');
      if (err.response?.data != null) {
        contentBuffer.writeln('\n[Response Error Body]\n${_prettyJsonEncode(maskedResponseErrorBody)}');
      }

      TcInspector.addLogEntry(LogEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        timestamp: DateTime.now(),
        type: LogType.network,
        title: '${options.method} ${options.path} - Error',
        content: contentBuffer.toString(),
        isError: true,
        error: err.toString(),
        stackTrace: err.stackTrace.toString(),
        metadata: {
          'method': options.method,
          'url': options.uri.toString(),
          'statusCode': err.response?.statusCode,
          'duration': duration,
          'requestHeaders': maskedRequestHeaders,
          'requestBody': maskedRequestData,
          'responseBody': maskedResponseErrorBody,
        },
      ));
    }

    return super.onError(err, handler);
  }

  String _prettyJsonEncode(dynamic data) {
    try {
      const encoder = JsonEncoder.withIndent('  ');
      final result = encoder.convert(data);
      if (result.length > 20000) {
        return '${result.substring(0, 20000)}\n\n... [TRUNCATED due to large payload size (${result.length} characters)] ...';
      }
      return result;
    } catch (_) {
      final str = data.toString();
      if (str.length > 20000) {
        return '${str.substring(0, 20000)}\n\n... [TRUNCATED due to large payload size (${str.length} characters)] ...';
      }
      return str;
    }
  }
}
