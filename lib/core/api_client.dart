import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_exception.dart';
import 'api_meta.dart';
import 'config.dart';
import 'token_storage.dart';

/// Isi amplop respons backend yang dibutuhkan layar.
class ApiPayload {
  ApiPayload({this.data, this.meta, this.message = 'OK'});

  final dynamic data;
  final ApiMeta? meta;
  final String message;

  Map<String, dynamic> get asMap => data is Map<String, dynamic>
      ? data as Map<String, dynamic>
      : <String, dynamic>{};

  List<Map<String, dynamic>> get asList => (data as List? ?? [])
      .map((item) => item as Map<String, dynamic>)
      .toList();
}

class ApiClient {
  ApiClient(this._tokens) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        headers: {'Accept': 'application/json'},
        // Status non-2xx ditangani sendiri agar pesan backend tetap utuh.
        validateStatus: (_) => true,
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _tokens.cachedToken;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final TokenStorage _tokens;
  late final Dio _dio;

  /// Dipanggil AuthProvider saat backend menjawab 401 pada endpoint selain
  /// login/register, supaya sesi mati di satu tempat saja.
  VoidCallback? onUnauthorized;

  /// Endpoint auth sengaja dikecualikan: password salah juga menjawab 401 dan
  /// tidak boleh menghapus sesi atau memicu pesan "sesi berakhir".
  static const _publicAuthPaths = {'/api/auth/login', '/api/auth/register'};

  Future<ApiPayload> get(String path, {Map<String, dynamic>? query}) {
    return _send(path, () => _dio.get(path, queryParameters: _clean(query)));
  }

  Future<ApiPayload> post(String path, {Object? body}) {
    return _send(path, () => _dio.post(path, data: body));
  }

  Future<ApiPayload> put(String path, {Object? body}) {
    return _send(path, () => _dio.put(path, data: body));
  }

  Future<ApiPayload> patch(String path, {Object? body}) {
    return _send(path, () => _dio.patch(path, data: body));
  }

  Future<ApiPayload> delete(String path) {
    return _send(path, () => _dio.delete(path));
  }

  /// FormData dipakai untuk semua unggahan; Content-Type sengaja tidak diatur
  /// manual supaya Dio menulis boundary multipart sendiri.
  Future<ApiPayload> postMultipart(String path, FormData formData) {
    return _send(path, () => _dio.post(path, data: formData));
  }

  Future<ApiPayload> _send(
    String path,
    Future<Response<dynamic>> Function() request,
  ) async {
    Response<dynamic> response;
    try {
      response = await request();
    } on DioException catch (error) {
      throw _networkError(error);
    }

    final body = response.data;
    final payload = body is Map<String, dynamic> ? body : <String, dynamic>{};
    if (payload['success'] == true) {
      return ApiPayload(
        data: payload['data'],
        meta: payload['meta'] is Map<String, dynamic>
            ? ApiMeta.fromJson(payload['meta'] as Map<String, dynamic>)
            : null,
        message: payload['message'] as String? ?? 'OK',
      );
    }

    throw _buildError(response, payload, isAuthCall: _publicAuthPaths.contains(path));
  }

  ApiException _buildError(
    Response<dynamic> response,
    Map<String, dynamic> payload, {
    required bool isAuthCall,
  }) {
    final status = response.statusCode ?? 0;
    final message =
        payload['message'] as String? ?? _fallbackMessage(status);

    final fieldErrors = <String, String>{};
    final rawErrors = payload['errors'];
    if (rawErrors is List) {
      for (final item in rawErrors) {
        if (item is Map && item['field'] is String && item['message'] is String) {
          fieldErrors.putIfAbsent(
            item['field'] as String,
            () => item['message'] as String,
          );
        }
      }
    }

    if (status == 401 && !isAuthCall) onUnauthorized?.call();

    return ApiException(message, statusCode: status, fieldErrors: fieldErrors);
  }

  ApiException _networkError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return ApiException(
          'Server tidak merespons. Server gratis mungkin sedang bangun, coba lagi sebentar.',
        );
      case DioExceptionType.badCertificate:
        return ApiException('Sertifikat server tidak valid.');
      case DioExceptionType.cancel:
        return ApiException('Permintaan dibatalkan.');
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return ApiException(
          'Tidak bisa terhubung ke server. Periksa koneksi internet.',
        );
      case DioExceptionType.badResponse:
        return ApiException('Server mengirim respons yang tidak dikenali.');
    }
  }

  String _fallbackMessage(int status) {
    switch (status) {
      case 400:
        return 'Permintaan tidak valid';
      case 401:
        return 'Sesi berakhir, silakan masuk lagi';
      case 403:
        return 'Anda tidak punya akses ke bagian ini';
      case 404:
        return 'Data tidak ditemukan';
      case 409:
        return 'Data bertentangan dengan data yang sudah ada';
      case 413:
        return 'Ukuran file maksimal 2 MB';
      case 415:
        return 'Tipe file harus jpg, png, atau webp';
      case 422:
        return 'Data tidak valid';
      case 429:
        return 'Terlalu banyak percobaan, coba lagi nanti';
      default:
        return 'Terjadi kesalahan pada server';
    }
  }

  Map<String, dynamic>? _clean(Map<String, dynamic>? query) {
    if (query == null) return null;
    final cleaned = <String, dynamic>{};
    query.forEach((key, value) {
      if (value == null) return;
      if (value is String && value.trim().isEmpty) return;
      cleaned[key] = value;
    });
    return cleaned;
  }
}
