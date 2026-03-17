import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../../core/constants/api_config.dart';
import '../../core/storage/token_storage.dart';

/// API HTTP 클라이언트
class ApiClient {
  ApiClient(this._tokenStorage) {
    final baseOptions = BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );
    _dio = Dio(
      baseOptions,
    );
    _refreshDio = Dio(baseOptions);
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _tokenStorage.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          _logRequest(options);
          return handler.next(options);
        },
        onResponse: (response, handler) {
          _logResponse(response);
          return handler.next(response);
        },
        onError: (error, handler) async {
          final recovered = await _tryRecoverWithRefresh(error);
          if (recovered != null) {
            _logResponse(recovered);
            return handler.resolve(recovered);
          }
          _handleUnauthorized(error);
          _logError(error);
          return handler.next(error);
        },
      ),
    );
  }

  late final Dio _dio;
  late final Dio _refreshDio;
  final TokenStorage _tokenStorage;
  Future<void> Function()? _onUnauthorized;
  bool _isHandlingUnauthorized = false;
  Future<bool>? _refreshFuture;

  Dio get dio => _dio;

  void setUnauthorizedHandler(Future<void> Function() handler) {
    _onUnauthorized = handler;
  }

  static const JsonEncoder _encoder = JsonEncoder.withIndent('  ');

  void _logRequest(RequestOptions options) {
    final payload = <String, dynamic>{
      'type': 'request',
      'method': options.method,
      'url': options.uri.toString(),
      'path': options.path,
      'queryParameters': options.queryParameters,
      'headers': options.headers,
      'data': _normalizeData(options.data),
    };
    _printJson(payload);
  }

  void _logResponse(Response<dynamic> response) {
    final payload = <String, dynamic>{
      'type': 'response',
      'method': response.requestOptions.method,
      'url': response.requestOptions.uri.toString(),
      'statusCode': response.statusCode,
      'statusMessage': response.statusMessage,
      'headers': response.headers.map,
      'data': _normalizeData(response.data),
    };
    _printJson(payload);
  }

  void _logError(DioException error) {
    final payload = <String, dynamic>{
      'type': 'error',
      'method': error.requestOptions.method,
      'url': error.requestOptions.uri.toString(),
      'message': error.message,
      'error': error.error?.toString(),
      'statusCode': error.response?.statusCode,
      'responseData': _normalizeData(error.response?.data),
    };
    _printJson(payload);
  }

  void _handleUnauthorized(DioException error) {
    final statusCode = error.response?.statusCode;
    if (statusCode != 401 || _isHandlingUnauthorized) return;
    _isHandlingUnauthorized = true;
    () async {
      try {
        await _tokenStorage.clearAll();
        if (_onUnauthorized != null) {
          await _onUnauthorized!();
        }
      } finally {
        _isHandlingUnauthorized = false;
      }
    }();
  }

  Future<Response<dynamic>?> _tryRecoverWithRefresh(
    DioException error,
  ) async {
    final statusCode = error.response?.statusCode;
    final request = error.requestOptions;
    final alreadyRetried = request.extra['retried_after_refresh'] == true;
    if (statusCode != 401 || alreadyRetried || _isAuthPath(request.path)) {
      return null;
    }

    final refreshed = await _refreshAccessToken();
    if (!refreshed) return null;

    final newAccessToken = _tokenStorage.getAccessToken();
    if (newAccessToken == null) return null;

    request.headers['Authorization'] = 'Bearer $newAccessToken';
    request.extra['retried_after_refresh'] = true;
    return _dio.fetch(request);
  }

  bool _isAuthPath(String path) {
    return path == '/auth/login' ||
        path == '/auth/signup' ||
        path == '/auth/refresh';
  }

  Future<bool> _refreshAccessToken() async {
    if (_refreshFuture != null) return _refreshFuture!;

    final completer = Future<bool>(() async {
      final refreshToken = _tokenStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) return false;
      try {
        final response = await _refreshDio.post<Map<String, dynamic>>(
          '/auth/refresh',
          data: {
            'refresh_token': refreshToken,
          },
        );
        final data = response.data ?? const <String, dynamic>{};
        final newAccessToken = data['access_token']?.toString();
        final newRefreshToken =
            data['refresh_token']?.toString() ?? refreshToken;
        if (newAccessToken == null || newAccessToken.isEmpty) return false;
        await _tokenStorage.saveTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
        );
        return true;
      } catch (_) {
        return false;
      }
    });

    _refreshFuture = completer;
    final ok = await completer;
    _refreshFuture = null;
    return ok;
  }

  Object? _normalizeData(Object? data) {
    if (data == null) return null;
    if (data is FormData) {
      return {
        'fields': {for (final field in data.fields) field.key: field.value},
        'files': [
          for (final file in data.files)
            {
              'key': file.key,
              'filename': file.value.filename,
              'contentType': file.value.contentType?.toString(),
            },
        ],
      };
    }
    return data;
  }

  void _printJson(Object payload) {
    final text = _encoder.convert(payload);
    _printLong(text);
  }

  void _printLong(String text) {
    const chunkSize = 800;
    for (var i = 0; i < text.length; i += chunkSize) {
      final end = (i + chunkSize < text.length) ? i + chunkSize : text.length;
      debugPrint(text.substring(i, end));
    }
  }
}
