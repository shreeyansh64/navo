import 'package:navo/core/api/api_error.dart';
import 'package:navo/core/storage/token_storage.dart';
import 'package:navo/features/auth/data/data_source/auth_remote_data_source.dart';
import 'package:navo/features/auth/domain/model/auth_models.dart';
import 'package:navo/features/auth/domain/repository/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remote;
  final TokenStorage tokenStorage;

  AuthRepositoryImpl({required this.remote, required this.tokenStorage});

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<void> _saveTokens(Map<String, dynamic> json) {
    final tokens = json['tokens'] as Map;
    return tokenStorage.saveTokens(access: tokens['access'], refresh: tokens['refresh']);
  }

  @override
  Future<LoginResult> login(String email, String password) => _guard(() async {
        final json = await remote.login(email.trim(), password);
        await _saveTokens(json);
        final result = LoginResult.fromJson(json);
        await tokenStorage.saveUser(role: result.role.name, email: email.trim().toLowerCase());
        return result;
      });

  @override
  Future<OtpInfo> register(String email, String password, String confirmPassword) => _guard(
      () async => OtpInfo.fromJson(await remote.register(email.trim(), password, confirmPassword)));

  @override
  Future<void> verifyRegistrationOtp(String email, String otp) => _guard(() async {
        await _saveTokens(await remote.verifyRegistrationOtp(email.trim(), otp));
        await tokenStorage.saveUser(role: UserRole.student.name, email: email.trim().toLowerCase());
      });

  @override
  Future<OtpInfo> forgotPassword(String email) =>
      _guard(() async => OtpInfo.fromJson(await remote.forgotPassword(email.trim())));

  @override
  Future<void> verifyForgotPasswordOtp(String email, String otp) =>
      _guard(() => remote.verifyForgotPasswordOtp(email.trim(), otp));

  @override
  Future<void> resetPassword(String email, String otp, String password, String confirmPassword) =>
      _guard(() => remote.resetPassword(email.trim(), otp, password, confirmPassword));

  @override
  Future<UserRole?> currentRole() async {
    if (await tokenStorage.refreshToken == null) return null;
    return UserRole.parse(await tokenStorage.role);
  }

  @override
  Future<void> logout() => tokenStorage.clear();
}
