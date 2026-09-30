part of 'forgot_password_bloc.dart';

sealed class ForgotPasswordEvent {}

class ForgotPasswordRequested extends ForgotPasswordEvent {
  final String email;
  ForgotPasswordRequested(this.email);
}

class ForgotOtpResent extends ForgotPasswordEvent {}

class ForgotOtpSubmitted extends ForgotPasswordEvent {
  final String otp;
  ForgotOtpSubmitted(this.otp);
}

class PasswordResetSubmitted extends ForgotPasswordEvent {
  final String password;
  final String confirmPassword;
  PasswordResetSubmitted({required this.password, required this.confirmPassword});
}
