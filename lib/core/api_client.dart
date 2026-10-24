import 'package:dio/dio.dart';

import 'constants.dart';

class ApiException implements Exception {
  final int code;
  final String message;

  ApiException(this.code, this.message);

  @override
  String toString() => message;
}

class ApiResponse {
  final int code;
  final String message;
  final dynamic data;

  ApiResponse({required this.code, required this.message, this.data});
}

final Dio _dio = Dio(
  BaseOptions(
    baseUrl: AppConstants.baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    sendTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json'},
  ),
);

dynamic _handle(Response response) {
  final body = response.data;
  final metadata = body is Map ? body['Metadata'] : null;
  final code = metadata is Map
      ? (metadata['code'] as int? ?? response.statusCode ?? 500)
      : (response.statusCode ?? 500);
  final message = metadata is Map ? (metadata['message']?.toString() ?? '') : '';
  final data = body is Map ? body['Data'] : null;

  if ((response.statusCode ?? 500) >= 400 || code >= 400) {
    throw ApiException(code, message.isEmpty ? 'Terjadi kesalahan' : message);
  }
  return data;
}

Never _mapError(Object e) {
  if (e is ApiException) throw e;
  if (e is DioException) {
    final response = e.response;
    if (response != null) {
      final body = response.data;
      final metadata = body is Map ? body['Metadata'] : null;
      final code = metadata is Map
          ? (metadata['code'] as int? ?? response.statusCode ?? 500)
          : (response.statusCode ?? 500);
      final message = metadata is Map ? (metadata['message']?.toString() ?? '') : '';
      throw ApiException(code, message.isEmpty ? 'Terjadi kesalahan' : message);
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        throw ApiException(408, 'Koneksi ke server timeout');
      case DioExceptionType.connectionError:
        throw ApiException(0, 'Tidak dapat terhubung ke server');
      case DioExceptionType.cancel:
        throw ApiException(499, 'Permintaan dibatalkan');
      default:
        throw ApiException(500, 'Terjadi kesalahan jaringan');
    }
  }
  throw ApiException(500, 'Terjadi kesalahan');
}

Future<dynamic> get(String path, [Map<String, String>? query]) async {
  try {
    final response = await _dio.get(path, queryParameters: query);
    return _handle(response);
  } catch (e) {
    _mapError(e);
  }
}

Future<dynamic> post(String path, Object? body) async {
  try {
    final response = await _dio.post(path, data: body ?? {});
    return _handle(response);
  } catch (e) {
    _mapError(e);
  }
}

Future<dynamic> patch(String path, Object? body) async {
  try {
    final response = await _dio.patch(path, data: body ?? {});
    return _handle(response);
  } catch (e) {
    _mapError(e);
  }
}

Future<dynamic> delete(String path) async {
  try {
    final response = await _dio.delete(path);
    return _handle(response);
  } catch (e) {
    _mapError(e);
  }
}
