part of 'complete_profile_bloc.dart';

class CompleteProfileState {
  final bool loading;
  final bool done;
  final ApiException? error;

  const CompleteProfileState({this.loading = false, this.done = false, this.error});
}
