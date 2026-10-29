import 'package:dio/dio.dart';
import 'api_exception.dart';
import 'connectivity_status.dart';
import 'tecta_inspector_interceptor.dart';
import 'smart_retry/retry_interceptor.dart';
import 'dio_error_util.dart';

enum MethodRequest { POST, GET, PUT, DELETE }

typedef ErrorParser = Exception Function(int? statusCode, dynamic responseData);

class TcHttp {
  TcHttp({
    required String baseUrl,
    Dio? dio,
    List<Interceptor>? interceptors,
    Duration connectTimeout = const Duration(seconds: 90),
    Duration? receiveTimeout = const Duration(seconds: 50),
    bool checkConnectivity = true,
    Future<bool> Function()? connectivityChecker,
    this.customErrorParser,
    ValidateStatus? validateStatus,
    // Logger settings
    bool logRequestUrl = true,
    bool logRequestHeader = false,
    bool logRequestBody = false,
    bool logResponseBody = true,
    bool logResponseHeader = false,
    bool logResponseError = true,
  })  : _checkConnectivity = checkConnectivity,
        _connectivityChecker = connectivityChecker {
    _dio = dio ?? Dio();
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = connectTimeout;
    _dio.options.receiveTimeout = receiveTimeout;
    _dio.options.headers.addAll({
      'Accept': 'application/json',
    });
    _dio.options.receiveDataWhenStatusError = true;
    // Only override Dio's default (2xx = success) when asked. Accepting 4xx as
    // success means 401s no longer reach AuthInterceptor's token refresh.
    if (validateStatus != null) {
      _dio.options.validateStatus = validateStatus;
    }

    // Add custom interceptors if provided
    if (interceptors != null) {
      _dio.interceptors.addAll(interceptors);
    }

    // Default Interceptor for default headers
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (!options.headers.containsKey("Accept")) {
            options.headers['Accept'] = 'application/json';
          }
          return handler.next(options);
        },
      ),
    );

    // TcInspectorInterceptor (Replaces LoggerInterceptor)
    _dio.interceptors.add(TcInspectorInterceptor(
      logRequestUrl: logRequestUrl,
      logRequestHeader: logRequestHeader,
      logResponseHeader: logResponseHeader,
      logRequestBody: logRequestBody,
      logResponseBody: logResponseBody,
      logResponseError: logResponseError,
    ));

    // Retry Interceptor
    _dio.interceptors.add(
      RetryInterceptor(
        dio: _dio,
        logPrint: (message) => logDebug(message, level: Level.debug),
        retries: 3,
        retryDelays: const [
          Duration(seconds: 1),
          Duration(seconds: 2),
          Duration(seconds: 3),
        ],
      ),
    );
  }

  late final Dio _dio;
  final bool _checkConnectivity;
  final Future<bool> Function()? _connectivityChecker;
  final ErrorParser? customErrorParser;

  Dio get dio => _dio;

  Future<Response> call(
    String url, {
    MethodRequest method = MethodRequest.POST,
    dynamic request,
    Map<String, dynamic>? header,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    bool useFormData = false,
    bool? logRequestUrl,
    bool? logRequestHeader,
    bool? logRequestBody,
    bool? logResponseBody,
    bool? logResponseHeader,
    bool? logResponseError,
  }) async {
    if (_checkConnectivity) {
      final isOnline = _connectivityChecker != null
          ? await _connectivityChecker()
          : await ConnectivityStatus.hasNetwork();
      if (!isOnline) {
        throw NoInternetException();
      }
    }

    final requestOptions = options ?? Options();
    if (header != null) {
      requestOptions.headers = (requestOptions.headers ?? {})..addAll(header);
    }

    requestOptions.extra ??= {};
    if (logRequestUrl != null) requestOptions.extra!['logRequestUrl'] = logRequestUrl;
    if (logRequestHeader != null) requestOptions.extra!['logRequestHeader'] = logRequestHeader;
    if (logRequestBody != null) requestOptions.extra!['logRequestBody'] = logRequestBody;
    if (logResponseBody != null) requestOptions.extra!['logResponseBody'] = logResponseBody;
    if (logResponseHeader != null) requestOptions.extra!['logResponseHeader'] = logResponseHeader;
    if (logResponseError != null) requestOptions.extra!['logResponseError'] = logResponseError;

    try {
      Response response;
      final dynamic body =
          (useFormData && request is Map<String, dynamic>) ? FormData.fromMap(request) : request;

      switch (method) {
        case MethodRequest.GET:
          response = await _dio.get(
            url,
            queryParameters: queryParameters ?? (request is Map<String, dynamic> ? request : null),
            options: requestOptions,
            cancelToken: cancelToken,
          );
          break;
        case MethodRequest.PUT:
          response = await _dio.put(
            url,
            data: body,
            queryParameters: queryParameters,
            options: requestOptions,
            cancelToken: cancelToken,
          );
          break;
        case MethodRequest.DELETE:
          response = await _dio.delete(
            url,
            data: body,
            queryParameters: queryParameters,
            options: requestOptions,
            cancelToken: cancelToken,
          );
          break;
        case MethodRequest.POST:
          response = await _dio.post(
            url,
            data: body,
            queryParameters: queryParameters,
            options: requestOptions,
            cancelToken: cancelToken,
          );
          break;
      }

      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      if (e is TcHttpException) rethrow;
      throw TcHttpException(message: e.toString());
    }
  }

  Future<Response> download(
    String url,
    String savePath, {
    ProgressCallback? onReceiveProgress,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
    bool? logRequestUrl,
    bool? logRequestHeader,
    bool? logRequestBody,
    bool? logResponseBody,
    bool? logResponseHeader,
    bool? logResponseError,
  }) async {
    if (_checkConnectivity) {
      final isOnline = _connectivityChecker != null
          ? await _connectivityChecker()
          : await ConnectivityStatus.hasNetwork();
      if (!isOnline) {
        throw NoInternetException();
      }
    }

    try {
      final requestOptions = options ?? Options();
      requestOptions.extra ??= {};
      if (logRequestUrl != null) requestOptions.extra!['logRequestUrl'] = logRequestUrl;
      if (logRequestHeader != null) requestOptions.extra!['logRequestHeader'] = logRequestHeader;
      if (logRequestBody != null) requestOptions.extra!['logRequestBody'] = logRequestBody;
      if (logResponseBody != null) requestOptions.extra!['logResponseBody'] = logResponseBody;
      if (logResponseHeader != null) requestOptions.extra!['logResponseHeader'] = logResponseHeader;
      if (logResponseError != null) requestOptions.extra!['logResponseError'] = logResponseError;

      final response = await _dio.download(
        url,
        savePath,
        onReceiveProgress: onReceiveProgress,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        options: requestOptions,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      if (e is TcHttpException) rethrow;
      throw TcHttpException(message: e.toString());
    }
  }

  Exception _handleDioError(DioException e) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;

    if (customErrorParser != null) {
      try {
        return customErrorParser!(statusCode, data);
      } catch (parserException) {
        // Fallback if parser fails
      }
    }

    final serverMessage = _extractServerMessage(data);
    final fallbackMessage = DioErrorUtil.handleError(e);
    final message = serverMessage ?? fallbackMessage;

    return ServerResponseException(
      message: message,
      statusCode: statusCode,
      data: data,
    );
  }

  String? _extractServerMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['message'] as String? ?? data['error'] as String? ?? data['msg'] as String?;
    }
    return null;
  }
}
