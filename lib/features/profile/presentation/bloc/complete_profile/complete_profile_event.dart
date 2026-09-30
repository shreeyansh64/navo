part of 'complete_profile_bloc.dart';

sealed class CompleteProfileEvent {}

class CompleteProfileSubmitted extends CompleteProfileEvent {
  final String fullName;
  final String section;
  final String studentNumber;
  final File? image;

  CompleteProfileSubmitted({
    required this.fullName,
    required this.section,
    required this.studentNumber,
    this.image,
  });
}
