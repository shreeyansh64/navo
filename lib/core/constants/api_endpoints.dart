class ApiEndpoints {
  static const register = '/auth/register/';
  static const verifyRegistrationOtp = '/auth/verify-registration-otp/';
  static const login = '/auth/login/';
  static const forgotPassword = '/auth/forgot-password/';
  static const verifyForgotPasswordOtp = '/auth/verify-forgot-password-otp/';
  static const resetPassword = '/auth/reset-password/';
  static const refresh = '/auth/refresh/';
  static const completeProfile = '/auth/complete-profile/';
  static const me = '/me/';
  static const gateScan = '/gate/scan/';
  static const gateAssignToken = '/gate/assign-token/';

  /// Endpoints that must never carry a Bearer token or trigger a refresh.
  static const public = {
    register,
    verifyRegistrationOtp,
    login,
    forgotPassword,
    verifyForgotPasswordOtp,
    resetPassword,
    refresh,
  };
}
