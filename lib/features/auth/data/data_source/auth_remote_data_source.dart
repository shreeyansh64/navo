import 'package:dio/dio.dart';
import 'package:navo/core/constants/api_endpoints.dart';

class AuthRemoteDataSource {
  final Dio dio;
  AuthRemoteDataSource({required this.dio});

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final res = await dio.post(path, data: body);
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> login(String email, String password) =>
      _post(ApiEndpoints.login, {'email': email, 'password': password});

  Future<Map<String, dynamic>> register(String email, String password, String confirmPassword) =>
      _post(ApiEndpoints.register,
          {'email': email, 'password': password, 'confirm_password': confirmPassword});

  Future<Map<String, dynamic>> verifyRegistrationOtp(String email, String otp) =>
      _post(ApiEndpoints.verifyRegistrationOtp, {'email': email, 'otp': otp});

  Future<Map<String, dynamic>> forgotPassword(String email) =>
      _post(ApiEndpoints.forgotPassword, {'email': email});

  Future<Map<String, dynamic>> verifyForgotPasswordOtp(String email, String otp) =>
      _post(ApiEndpoints.verifyForgotPasswordOtp, {'email': email, 'otp': otp});

  Future<Map<String, dynamic>> resetPassword(
          String email, String otp, String password, String confirmPassword) =>
      _post(ApiEndpoints.resetPassword, {
        'email': email,
        'otp': otp,
        'password': password,
        'confirm_password': confirmPassword,
      });
}
