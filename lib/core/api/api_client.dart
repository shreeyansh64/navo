import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:navo/core/constants/api_endpoints.dart';
import 'package:navo/core/storage/token_storage.dart';

class ApiClient {
  final TokenStorage tokenStorage;

  /// Called when the refresh token is rejected. The app decides how to navigate.
  void Function()? onSessionExpired;

  late final Dio dio;

  /// Bare client for refresh and retries, so they never re-enter the auth interceptor.
  late final Dio _plainDio;

  ApiClient({required this.tokenStorage}) {
    var base = (dotenv.env['BASE_URL'] ?? '').trim();
    if (base.isEmpty) {
      throw StateError('BASE_URL is not defined in .env');
    }
    if (!base.endsWith('/')) base = '$base/';
    final options = BaseOptions(
      baseUrl: base,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
    );
    dio = Dio(options)..interceptors.add(_AuthInterceptor(this));
    _plainDio = Dio(options);
  }
}

class _AuthInterceptor extends QueuedInterceptor {
  final ApiClient client;
  _AuthInterceptor(this.client);

  TokenStorage get _storage => client.tokenStorage;

  bool _isPublic(RequestOptions o) {
    final path = o.path.startsWith('/') ? o.path.substring(1) : o.path;
    return ApiEndpoints.public.any((p) {
      final cleanP = p.startsWith('/') ? p.substring(1) : p;
      return cleanP == path;
    });
  }

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (!_isPublic(options)) {
      final token = await _storage.accessToken;
      if (token != null) options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    if (err.response?.statusCode != 401 || _isPublic(options) || options.extra['retried'] == true) {
      return handler.next(err);
    }

    // Requests queued behind a refresh may already have a newer token than the one they sent.
    final sentWith = options.headers['Authorization'];
    var access = await _storage.accessToken;
    if (access == null || sentWith == 'Bearer $access') {
      access = await _refresh();
      if (access == null) return handler.next(err);
    }

    try {
      options
        ..headers['Authorization'] = 'Bearer $access'
        ..extra['retried'] = true;
      if (options.data is FormData) options.data = (options.data as FormData).clone();
      handler.resolve(await client._plainDio.fetch(options));
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  /// Returns the new access token, or null if the refresh did not succeed.
  Future<String?> _refresh() async {
    final refresh = await _storage.refreshToken;
    if (refresh == null) {
      await _expire();
      return null;
    }
    try {
      final res = await client._plainDio.post(ApiEndpoints.refresh, data: {'refresh': refresh});
      final access = res.data['access'] as String;
      // Refresh tokens rotate, so the new one must be stored too.
      await _storage.saveTokens(access: access, refresh: res.data['refresh'] as String);
      return access;
    } on DioException catch (e) {
      // Only a rejected token ends the session. Network failures keep it for a later retry.
      if (e.response != null) await _expire();
      return null;
    }
  }

  Future<void> _expire() async {
    await _storage.clear();
    client.onSessionExpired?.call();
  }
}
