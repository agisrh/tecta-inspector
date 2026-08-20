import 'package:dio/dio.dart';

/// A professional interceptor to handle authentication via Bearer tokens.
class AuthInterceptor extends Interceptor {
  /// Creates an [AuthInterceptor].
  AuthInterceptor({
    required this.tokenProvider,
    this.refreshTokenProvider,
    this.excludePaths,
    this.authPrefix = 'Bearer',
    this.headerKey = 'Authorization',
    this.dio,
  });

  /// Callback to retrieve the authentication token.
  final Future<String?> Function() tokenProvider;

  /// Callback to refresh the token when it is expired.
  final Future<String?> Function()? refreshTokenProvider;

  /// Optional list of paths that do NOT require authentication.
  final List<String>? excludePaths;

  /// Format of the Authorization header prefix. Defaults to "Bearer".
  final String authPrefix;

  /// The header key to use. Defaults to "Authorization".
  final String headerKey;

  /// Dio instance used to retry the requests.
  final Dio? dio;

  bool _isRefreshing = false;
  final List<MapEntry<RequestOptions, ErrorInterceptorHandler>> _requestQueue = [];

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final bool isExcluded = excludePaths?.any((path) => options.path.contains(path)) ?? false;

    if (!isExcluded) {
      final token = await tokenProvider();
      if (token != null && token.isNotEmpty) {
        options.headers[headerKey] = '$authPrefix $token'.trim();
      }
    }

    return super.onRequest(options, handler);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;
    final bool isExcluded = excludePaths?.any((path) => err.requestOptions.path.contains(path)) ?? false;

    if (statusCode == 401 && !isExcluded && refreshTokenProvider != null && dio != null) {
      if (_isRefreshing) {
        _requestQueue.add(MapEntry(err.requestOptions, handler));
        return;
      }

      _isRefreshing = true;

      try {
        final newToken = await refreshTokenProvider!();
        if (newToken != null && newToken.isNotEmpty) {
          // Retry current failed request
          final response = await _retryRequest(err.requestOptions, newToken);
          handler.resolve(response);

          // Retry all queued requests
          for (final queued in _requestQueue) {
            try {
              final queuedResponse = await _retryRequest(queued.key, newToken);
              queued.value.resolve(queuedResponse);
            } on DioException catch (queuedErr) {
              queued.value.next(queuedErr);
            } catch (queuedErr) {
              queued.value.next(DioException(requestOptions: queued.key, error: queuedErr));
            }
          }
          _requestQueue.clear();
          return;
        } else {
          // Refresh token is null or empty, reject all queued requests
          for (final queued in _requestQueue) {
            queued.value.next(err);
          }
          _requestQueue.clear();
          handler.next(err);
          return;
        }
      } catch (refreshErr) {
        // Refresh token failed, reject all queued requests
        for (final queued in _requestQueue) {
          queued.value.next(err);
        }
        _requestQueue.clear();
        handler.next(err);
        return;
      } finally {
        _isRefreshing = false;
      }
    }

    return super.onError(err, handler);
  }

  Future<Response<dynamic>> _retryRequest(RequestOptions requestOptions, String token) {
    final options = Options(
      method: requestOptions.method,
      headers: Map<String, dynamic>.from(requestOptions.headers)
        ..[headerKey] = '$authPrefix $token'.trim(),
      extra: requestOptions.extra,
      responseType: requestOptions.responseType,
      contentType: requestOptions.contentType,
      validateStatus: requestOptions.validateStatus,
      receiveTimeout: requestOptions.receiveTimeout,
      sendTimeout: requestOptions.sendTimeout,
    );

    return dio!.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
      cancelToken: requestOptions.cancelToken,
      onSendProgress: requestOptions.onSendProgress,
      onReceiveProgress: requestOptions.onReceiveProgress,
    );
  }
}
