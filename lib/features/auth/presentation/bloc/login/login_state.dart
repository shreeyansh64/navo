part of 'login_bloc.dart';

class LoginState {
  final bool loading;
  final ApiException? error;
  final LoginResult? result;

  const LoginState({this.loading = false, this.error, this.result});
}
