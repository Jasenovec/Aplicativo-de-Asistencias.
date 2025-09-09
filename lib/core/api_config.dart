import 'package:dio/dio.dart';

class ApiConfig {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'http://34.123.32.110:3000',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  // IP vm 34.123.32.110
  // IP solmar: 192.168.137.1
  // IP de mi casa: 192.168.0.192

  static bool _attached = false;

  static void attachAuthInterceptor({
    required Future<String?> Function() getToken,
    void Function()? onUnauthorized,
  }) {
    if (_attached) return;
    dio.interceptors.add(_AuthInterceptor(getToken, onUnauthorized));
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
    _attached = true;
  }
}

class _AuthInterceptor extends Interceptor {
  final Future<String?> Function() _getToken;
  final void Function()? _onUnauthorized;

  _AuthInterceptor(this._getToken, this._onUnauthorized);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!options.path.contains('/auth/login')) {
      final token = await _getToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      _onUnauthorized?.call();
    }
    handler.next(err);
  }
}
