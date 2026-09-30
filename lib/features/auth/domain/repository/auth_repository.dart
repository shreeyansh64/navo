import 'package:navo/features/auth/domain/model/auth_models.dart';

/// All methods throw ApiException on failure.
abstract class AuthRepository {
  Future<LoginResult> login(String email, String password);

  Future<OtpInfo> register(String email, String password, String confirmPassword);
  Future<void> verifyRegistrationOtp(String email, String otp);

  Future<OtpInfo> forgotPassword(String email);
  Future<void> verifyForgotPasswordOtp(String email, String otp);
  Future<void> resetPassword(String email, String otp, String password, String confirmPassword);

  /// Role of the stored session, or null when logged out.
  Future<UserRole?> currentRole();
  Future<void> logout();
}
