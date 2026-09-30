part of 'forgot_password_bloc.dart';

enum ForgotStep { email, otp, reset, done }

class ForgotPasswordState {
  final ForgotStep step;
  final bool loading;
  final ApiException? error;
  final String email;

  /// Verified OTP, kept in memory only. /verify-forgot-password-otp/ doesn't consume it,
  /// so it must be sent again with the new password.
  final String otpCode;
  final OtpTimer otp;

  const ForgotPasswordState({
    this.step = ForgotStep.email,
    this.loading = false,
    this.error,
    this.email = '',
    this.otpCode = '',
    this.otp = const OtpTimer(),
  });

  /// [error] is not carried over: every new state clears it unless passed again.
  ForgotPasswordState copyWith({
    ForgotStep? step,
    bool? loading,
    ApiException? error,
    String? email,
    String? otpCode,
    OtpTimer? otp,
  }) =>
      ForgotPasswordState(
        step: step ?? this.step,
        loading: loading ?? this.loading,
        error: error,
        email: email ?? this.email,
        otpCode: otpCode ?? this.otpCode,
        otp: otp ?? this.otp,
      );
}
