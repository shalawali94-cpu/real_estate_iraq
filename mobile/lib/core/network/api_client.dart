import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/env.dart';

/// Thrown for non-2xx API responses. `code` is the stable server error code.
class ApiException implements Exception {
  ApiException(this.code, [this.status]);
  final String code;
  final int? status;
  @override
  String toString() => 'ApiException($code, $status)';
}

/// Calls the Vercel backend with the user's Supabase access token.
/// Business rules are enforced server-side; the client never decides them.
class ApiClient {
  ApiClient(this._dio);
  final Dio _dio;

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        path,
        data: body,
        options: Options(headers: {if (token != null) 'Authorization': 'Bearer $token'}),
      );
      return res.data ?? const {};
    } on DioException catch (e) {
      final data = e.response?.data;
      final code = (data is Map && data['error'] is Map)
          ? (data['error']['code'] as String? ?? 'INTERNAL')
          : (data is Map ? (data['code'] as String? ?? 'INTERNAL') : 'NETWORK');
      throw ApiException(code, e.response?.statusCode);
    }
  }
}

final apiClientProvider = Provider<ApiClient?>((ref) {
  if (Env.apiBaseUrl.isEmpty) return null;
  return ApiClient(Dio(BaseOptions(
    baseUrl: Env.apiBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
  )));
});
