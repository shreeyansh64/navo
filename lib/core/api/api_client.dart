import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:navo/features/auth/presentation/pages/login_page.dart';
import 'package:navo/main.dart';

class ApiClient {
  final FlutterSecureStorage storage;
  final baseUrl = dotenv.env['BASE_URL'];
  ApiClient({required this.storage});
  Dio getDio() {
    Dio dio = Dio(
      BaseOptions(
        baseUrl: baseUrl!,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await storage.read(key: 'access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },

        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            final refreshed = await _refreshToken();
            if (refreshed) {
              final retryResponse = await _retry(dio, error.requestOptions);
              return handler.resolve(retryResponse);
            } else {
              await _clearTokens();

              navigatorKey.currentState?.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            }
          }
          return handler.next(error);
        },
      ),
    );
    return dio;
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await storage.read(key: 'refresh_token');
      if (refreshToken == null) return false;

      final response = await Dio().post(
        "$baseUrl/api/auth/refresh/",
        data: {"refresh_token": refreshToken},
      );
      await storage.write(
        key: 'access_token',
        value: response.data['access_token'],
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Response> _retry(Dio dio, RequestOptions requestOptions) async {
    final token = await storage.read(key: 'access_token');
    requestOptions.headers['Authorization'] = 'Bearer $token';
    return await dio.fetch(requestOptions);
  }

  Future<void> _clearTokens() async {
    await storage.delete(key: 'access_token');
    await storage.delete(key: 'refresh_token');
  }
}
