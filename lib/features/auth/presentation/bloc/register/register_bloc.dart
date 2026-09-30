import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:navo/core/api/api_error.dart';
import 'package:navo/features/auth/domain/repository/auth_repository.dart';
import 'package:navo/features/auth/presentation/bloc/otp_timer.dart';

part 'register_event.dart';
part 'register_state.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final AuthRepository repository;

  RegisterBloc({required this.repository}) : super(const RegisterState()) {
    on<RegisterSubmitted>((event, emit) async {
      final next = state.copyWith(
        step: RegisterStep.form,
        email: event.email,
        password: event.password,
        confirmPassword: event.confirmPassword,
      );
      emit(next.copyWith(loading: true));
      await _sendOtp(next, emit);
    });

    on<RegisterOtpResent>((event, emit) async {
      emit(state.copyWith(loading: true));
      await _sendOtp(state, emit);
    });

    on<RegisterOtpSubmitted>((event, emit) async {
      emit(state.copyWith(loading: true));
      try {
        await repository.verifyRegistrationOtp(state.email, event.otp);
        emit(state.copyWith(loading: false, step: RegisterStep.done));
      } on ApiException catch (e) {
        emit(state.copyWith(loading: false, error: e, otp: state.otp.afterError(e)));
      }
    });
  }

  Future<void> _sendOtp(RegisterState from, Emitter<RegisterState> emit) async {
    try {
      final info = await repository.register(from.email, from.password, from.confirmPassword);
      emit(from.copyWith(loading: false, step: RegisterStep.otp, otp: from.otp.sent(info)));
    } on ApiException catch (e) {
      // A cooldown means a code is already on its way, so let the user enter it.
      final cooling = e.code == ApiErrorCode.otpCooldown;
      emit(from.copyWith(
        loading: false,
        error: e,
        step: cooling ? RegisterStep.otp : null,
        otp: from.otp.afterError(e),
      ));
    }
  }
}
