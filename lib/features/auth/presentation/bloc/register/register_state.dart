part of 'register_bloc.dart';

enum RegisterStep { form, otp, done }

class RegisterState {
  final RegisterStep step;
  final bool loading;
  final ApiException? error;
  final String email;
  final String password;
  final String confirmPassword;
  final OtpTimer otp;

  const RegisterState({
    this.step = RegisterStep.form,
    this.loading = false,
    this.error,
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.otp = const OtpTimer(),
  });

  /// [error] is not carried over: every new state clears it unless passed again.
  RegisterState copyWith({
    RegisterStep? step,
    bool? loading,
    ApiException? error,
    String? email,
    String? password,
    String? confirmPassword,
    OtpTimer? otp,
  }) =>
      RegisterState(
        step: step ?? this.step,
        loading: loading ?? this.loading,
        error: error,
        email: email ?? this.email,
        password: password ?? this.password,
        confirmPassword: confirmPassword ?? this.confirmPassword,
        otp: otp ?? this.otp,
      );
}
