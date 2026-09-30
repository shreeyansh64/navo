import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:navo/core/api/api_error.dart';
import 'package:navo/features/profile/domain/repository/profile_repository.dart';

part 'complete_profile_event.dart';
part 'complete_profile_state.dart';

class CompleteProfileBloc extends Bloc<CompleteProfileEvent, CompleteProfileState> {
  final ProfileRepository repository;

  CompleteProfileBloc({required this.repository}) : super(const CompleteProfileState()) {
    on<CompleteProfileSubmitted>((event, emit) async {
      emit(const CompleteProfileState(loading: true));
      try {
        await repository.completeProfile(
          fullName: event.fullName,
          section: event.section,
          year: event.year,
          branch: event.branch,
          studentNumber: event.studentNumber,
          image: event.image,
        );
        emit(const CompleteProfileState(done: true));
      } on ApiException catch (e) {
        // Already completed (e.g. on another device): nothing left to do here.
        if (e.code == ApiErrorCode.profileExists) return emit(const CompleteProfileState(done: true));
        emit(CompleteProfileState(error: e));
      }
    });
  }
}
