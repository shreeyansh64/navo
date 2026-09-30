part of 'register_bloc.dart';

sealed class RegisterEvent {}

class RegisterSubmitted extends RegisterEvent {
  final String email;
  final String password;
  final String confirmPassword;
  RegisterSubmitted({required this.email, required this.password, required this.confirmPassword});
}

class RegisterOtpSubmitted extends RegisterEvent {
  final String otp;
  RegisterOtpSubmitted(this.otp);
}

/// Resending means calling /auth/register/ again with the same credentials.
class RegisterOtpResent extends RegisterEvent {}
