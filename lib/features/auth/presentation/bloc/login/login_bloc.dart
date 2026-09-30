import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:navo/core/api/api_error.dart';
import 'package:navo/features/auth/domain/model/auth_models.dart';
import 'package:navo/features/auth/domain/repository/auth_repository.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthRepository repository;

  LoginBloc({required this.repository}) : super(const LoginState()) {
    on<LoginSubmitted>((event, emit) async {
      emit(const LoginState(loading: true));
      try {
        emit(LoginState(result: await repository.login(event.email, event.password)));
      } on ApiException catch (e) {
        emit(LoginState(error: e));
      }
    });
  }
}
