import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiClient {
  ApiClient({Dio? dio}) : _dio = dio ?? Dio(_defaultOptions) {
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestBody: true,
          requestHeader: true,
          responseHeader: false,
          responseBody: true,
          error: true,
        ),
      );
    }
  }

  static const String _baseUrl = 'https://api.mytravaly.com/public/v1/';
  static const String _authToken = '71523fdd8d26f585315b4233e39d9263';

  static final BaseOptions _defaultOptions = BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 20),
    headers: <String, dynamic>{
      // API requires authtoken and (after device registration) visitortoken
      'authtoken': _authToken,
      'Accept': 'application/json',
    },
  );

  final Dio _dio;

  void setVisitorToken(String token) {
    _dio.options.headers['visitortoken'] = token;
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    );
  }
}
