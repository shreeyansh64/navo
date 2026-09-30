import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:navo/core/api/api_error.dart';
import 'package:navo/features/auth/domain/repository/auth_repository.dart';
import 'package:navo/features/auth/presentation/bloc/otp_timer.dart';

part 'forgot_password_event.dart';
part 'forgot_password_state.dart';

class ForgotPasswordBloc extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  final AuthRepository repository;

  ForgotPasswordBloc({required this.repository}) : super(const ForgotPasswordState()) {
    on<ForgotPasswordRequested>((event, emit) async {
      emit(state.copyWith(loading: true, email: event.email, step: ForgotStep.email));
      await _sendOtp(emit);
    });

    on<ForgotOtpResent>((event, emit) async {
      emit(state.copyWith(loading: true));
      await _sendOtp(emit);
    });

    on<ForgotOtpSubmitted>((event, emit) async {
      emit(state.copyWith(loading: true));
      try {
        await repository.verifyForgotPasswordOtp(state.email, event.otp);
        emit(state.copyWith(loading: false, step: ForgotStep.reset, otpCode: event.otp));
      } on ApiException catch (e) {
        emit(state.copyWith(loading: false, error: e, otp: state.otp.afterError(e)));
      }
    });

    on<PasswordResetSubmitted>((event, emit) async {
      emit(state.copyWith(loading: true));
      try {
        await repository.resetPassword(
            state.email, state.otpCode, event.password, event.confirmPassword);
        emit(state.copyWith(loading: false, step: ForgotStep.done));
      } on ApiException catch (e) {
        emit(state.copyWith(loading: false, error: e));
      }
    });
  }

  Future<void> _sendOtp(Emitter<ForgotPasswordState> emit) async {
    try {
      final info = await repository.forgotPassword(state.email);
      emit(state.copyWith(loading: false, step: ForgotStep.otp, otp: state.otp.sent(info)));
    } on ApiException catch (e) {
      emit(state.copyWith(loading: false, error: e, otp: state.otp.afterError(e)));
    }
  }
}
